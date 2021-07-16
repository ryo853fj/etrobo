/**
 ******************************************************************************
 ** ファイル名 : app.c
 **
 ** 概要 : 二輪差動型ライントレースロボットのTOPPERS/HRP3用Cサンプルプログラム
 **
 ** 注記 : sample_c4 (sample_c3にBluetooth通信リモートスタート機能を追加)
 ******************************************************************************
 **/
#include "app.h"


#if defined(BUILD_MODULE)
#include "module_cfg.h"
#else
#include "kernel_cfg.h"
#endif

#define DEBUG

#if defined(DEBUG)
#define _debug(x) (x)
#else
#define _debug(x)
#endif

#if defined(MAKE_BT_DISABLE)
static const int _bt_enabled = 0;
#else
static const int _bt_enabled = 1;
#endif

/**
 * シミュレータかどうかの定数を定義します
 */
#if defined(MAKE_SIM)
static const int _SIM = 1;
#elif defined(MAKE_EV3)
static const int _SIM = 0;
#else
static const int _SIM = 0;
#endif

/**
 * 左コース/右コース向けの設定を定義します
 * デフォルトは左コース(ラインの右エッジをトレース)です
 */
#if defined(MAKE_RIGHT)
static const int _LEFT = 0;
#define _EDGE -1
#else
static const int _LEFT = 1;
#define _EDGE 1
#endif

/**
 * センサー、モーターの接続を定義します
 */
static const sensor_port_t
    touch_sensor = EV3_PORT_1,
    color_sensor = EV3_PORT_2,
    sonar_sensor = EV3_PORT_3,
    gyro_sensor = EV3_PORT_4;

static const motor_port_t
    arm_motor = EV3_PORT_A,
    left_motor = EV3_PORT_C,
    right_motor = EV3_PORT_B;
//tail_motor  = EV3_PORT_D;

static int bt_cmd = 0;  /* Bluetoothコマンド 1:リモートスタート */
static FILE *bt = NULL; /* Bluetoothファイルハンドル */

typedef enum
{
 BASIC,
 PET,
 GARAGE,
}STATE;


typedef struct this_st
{
    STATE state;
    
} this_t;

static this_t this = {
    .state = BASIC
};

// static int main_change = BASIC; /*切り替えよう */

/* 下記のマクロは個体/環境に合わせて変更する必要があります */
/* sample_c1マクロ */
#define LIGHT_WHITE 23 /* 白色の光センサ値 */
#define LIGHT_BLACK 0  /* 黒色の光センサ値 */
/* sample_c2マクロ */
#define SONAR_ALERT_DISTANCE 30 /* 超音波センサによる障害物検知距離[cm] */
/* sample_c4マクロ */
//#define DEVICE_NAME     "ET0"  /* Bluetooth名 sdcard:\ev3rt\etc\rc.conf.ini LocalNameで設定 */
//#define PASS_KEY        "1234" /* パスキー    sdcard:\ev3rt\etc\rc.conf.ini PinCodeで設定 */
#define CMD_START '1' /* リモートスタートコマンド */

/*EV3機体*/
#define TIRE_RADIUS (4.5F)          /* タイヤ半径[cm]       */
#define TREAD_WIDTH (14.0F)         /* トレッド幅[cm]       */
#define DEG2RADIAN (0.01745329251F) /* 弧度法変換[π/180.0] */
#define PI 3.1415926                /*円周率*/

//PID
#define TIME 0.010 /*PID制御周期*/

/* LCDフォントサイズ */
#define CALIB_FONT (EV3_FONT_SMALL)
#define CALIB_FONT_WIDTH (6 /*TODO: magic number*/)
#define CALIB_FONT_HEIGHT (8 /*TODO: magic number*/)

/* 関数プロトタイプ宣言 */
void init(void);
static int sonar_alert(void);
static void _syslog(int level, char *text);
static void _log(char *text);

int pid_control(float kp, float ki, float kd, int target, int sensor_val, int pid_offset, int reset_i);
float get_my_position(void);
float get_my_yaw_euler(void);
static void arm_control(signed int angle);
//static void tail_control(signed int angle);
//static void backlash_cancel(signed char lpwm, signed char rpwm, int32_t *lenc, int32_t *renc);


/* メインタスク */
void main_task(intptr_t unused)
{
    signed char forward;      /* 前後進命令 */
    signed char turn;         /* 旋回命令 */
    signed char pwm_L, pwm_R; /* 左右モーターPWM出力 */
    static int val_reflect; /* 光センサー値 */


    /*キャリブレーション（1分間）*/
    //必要であれば、キャリブレーションの処理を書く

    init();//初期化

    /* スタート待機 */
    while (1)
    {
        /*実機用のリモートスタート*/
        if (bt_cmd == 1)
        {
            break; /* リモートスタート */
        }

        if (ev3_touch_sensor_is_pressed(touch_sensor) == 1)
        {
            this.state = BASIC;
            break; /* タッチセンサが押された */
        }

        tslp_tsk(10 * 1000U); /* 10msecウェイト */
    }
    /* 走行モーターエンコーダーリセット */
    ev3_motor_reset_counts(left_motor);
    ev3_motor_reset_counts(right_motor);
    ev3_motor_reset_counts(arm_motor);
    ev3_led_set_color(LED_GREEN); /* スタート通知 */
    /**
    * Main loop
    */
    while (1)
    {
        if (ev3_button_is_pressed(BACK_BUTTON))
            break;
        switch (this.state)
        {
        case BASIC:
            if(LineTrace_do())
            {
                this.state = PET;
                break;
            }

        case PET:
            if(pet_do())
            {
                this.state = GARAGE;
                break;
            }
        case GARAGE:
            //チーム３のプログラム(難所＿ブロック運び+ガレージ)
            //ガレージ前の青線座標　　X=24.2 Y=0 Z=8 ROT=180
            //例：（直進と障害物検知＿停止）
            // if (sonar_alert() == 1) /* 障害物検知 */
            // {
            //     forward = turn = 0; /* 障害物を検知したら停止 */
            // }
            // else
            // {
            //     forward = 50;
            //     turn = 0;
            // }
            // ev3_motor_steer(left_motor, right_motor, (int)forward, (int)turn);
            break;
        default:
            ETRoboc_notifyCompletedToSimulator();
        }

        // if (main_change == 4)
        //     break;

        tslp_tsk(10 * 1000U); /* 4msec周期起動 */
    }

    ev3_motor_stop(left_motor, false);
    ev3_motor_stop(right_motor, false);
    /*競技終了通知*/
    ETRoboc_notifyCompletedToSimulator();

    if (_bt_enabled)
    {
        ter_tsk(BT_TASK);
        fclose(bt);
    }

    ext_tsk();
}

void init(void)
{
    /* LCD画面表示 */
    ev3_lcd_fill_rect(0, 0, EV3_LCD_WIDTH, EV3_LCD_HEIGHT, EV3_LCD_WHITE);

    _log("bbbbbbb");
    //_log("HackEV ファイル名");
    _log("HackEV monolith2021_master");
    if (_LEFT)
        _log("Left course:");
    else
        _log("Right course:");

    /* センサー入力ポートの設定 */
    ev3_sensor_config(sonar_sensor, ULTRASONIC_SENSOR);
    ev3_sensor_config(color_sensor, COLOR_SENSOR);
    ev3_color_sensor_get_reflect(color_sensor); /* 反射率モード */
    ev3_sensor_config(touch_sensor, TOUCH_SENSOR);

    ev3_sensor_config(gyro_sensor, GYRO_SENSOR);
    ev3_gyro_sensor_reset(gyro_sensor);
    /* モーター出力ポートの設定 */
    ev3_motor_config(left_motor, LARGE_MOTOR);
    ev3_motor_config(right_motor, LARGE_MOTOR);
    ev3_motor_config(arm_motor, LARGE_MOTOR);
    /*なくてもいい*/
    if (_bt_enabled)
    {
        /* Open Bluetooth file */
        bt = ev3_serial_open_file(EV3_SERIAL_BT);
        assert(bt != NULL);

        /* Bluetooth通信タスクの起動 */
        act_tsk(BT_TASK);
    }

    ev3_led_set_color(LED_ORANGE); /* 初期化完了通知 */

    _log("Go to the start, ready?");
    if (_SIM)
        _log("Hit SPACE bar to start");
    else
        _log("Tap Touch Sensor to start");
    /*なくてもいい*/
    if (_bt_enabled)
    {
        fprintf(bt, "Bluetooth Remote Start: Ready.\n", EV3_SERIAL_BT);
        fprintf(bt, "send '1' to start\n", EV3_SERIAL_BT);
    }
}

//*****************************************************************************
// 関数名 : sonar_alert
// 引数 : 無し
// 返り値 : 1(障害物あり)/0(障害物無し)
// 概要 : 超音波センサによる障害物検知
//*****************************************************************************
static int sonar_alert(void)
{
    static unsigned int counter = 0;
    static int alert = 0;

    signed int distance;

    if (++counter == 40 / 10) /* 約40msec周期毎に障害物検知  */
    {
        /*
         * 超音波センサによる距離測定周期は、超音波の減衰特性に依存します。
         * NXTの場合は、40msec周期程度が経験上の最短測定周期です。
         * EV3の場合は、要確認
         */
        distance = ev3_ultrasonic_sensor_get_distance(sonar_sensor);
        if ((distance <= SONAR_ALERT_DISTANCE) && (distance >= 0))
        {
            alert = 1; /* 障害物を検知 */
        }
        else
        {
            alert = 0; /* 障害物無し */
        }
        counter = 0;
    }

    return alert;
}

//*****************************************************************************
// 関数名 : bt_task
// 引数 : unused
// 返り値 : なし
// 概要 : Bluetooth通信によるリモートスタート。 Tera Termなどのターミナルソフトから、
//       ASCIIコードで1を送信すると、リモートスタートする。
//*****************************************************************************
void bt_task(intptr_t unused)
{
    while (1)
    {
        if (_bt_enabled)
        {
            uint8_t c = fgetc(bt); /* 受信 */
            switch (c)
            {
            case '1':
                bt_cmd = 1;
                break;
            default:
                break;
            }
            fputc(c, bt); /* エコーバック */
        }
    }
}

//*****************************************************************************
// 関数名 : _syslog
// 引数 :   int   level - SYSLOGレベル
//          char* text  - 出力文字列
// 返り値 : なし
// 概要 : SYSLOGレベルlebelのログメッセージtextを出力します。
//        SYSLOGレベルはRFC3164のレベル名をそのまま（ERRだけはERROR）
//        `LOG_WARNING`の様に定数で指定できます。
//*****************************************************************************
static void _syslog(int level, char *text)
{
    static int _log_line = 0;
    if (_SIM)
    {
        syslog(level, text);
    }
    else
    {
        ev3_lcd_draw_string(text, 0, CALIB_FONT_HEIGHT * _log_line++);
    }
}

//*****************************************************************************
// 関数名 : _log
// 引数 :   char* text  - 出力文字列
// 返り値 : なし
// 概要 : SYSLOGレベルNOTICEのログメッセージtextを出力します。
//*****************************************************************************
static void _log(char *text)
{
    _syslog(LOG_NOTICE, text);
}
//*******************************************************************************//
//関数名:get_my_position()
//引数:void
//返り値:int(cm)
//概要:スタート時から現時点までの距離を計測し,返す
//*******************************************************************************//
float get_my_position(void)
{
    float left = 0, right = 0, distance = 0;

    /*走行距離*/
    left = ((float)ev3_motor_get_counts(left_motor) / 360.0) * 2.0 * PI * TIRE_RADIUS;
    right = ((float)ev3_motor_get_counts(right_motor) / 360.0) * 2.0 * PI * TIRE_RADIUS;

    distance = (left + right) / 2.0;
    return (float)distance;
}
//*******************************************************************************//
//関数名:get_my_yaw_euler()
//引数:void
//返り値:int(euler)
//概要:リセット時を基準方向として,現時点のロボットのYAW角を計測し,返す
//*******************************************************************************//
float get_my_yaw_euler(void)
{
    float left = 0, right = 0, euler = 0;

    left = (float)ev3_motor_get_counts(left_motor) * TIRE_RADIUS;
    right = (float)ev3_motor_get_counts(right_motor) * TIRE_RADIUS;

    euler = (left - right) / TREAD_WIDTH; //*2*360;//割る数は車輪間隔の幅
    return (float)euler;
}
//=================================================================//
// 関数名 : pid_control()
// 引数 : kp(P制御係数), ki(I制御係数), kd(D制御係数), target(目標値), sensor_val(光センサの値)
// 返り値 : PID制御値(走行体旋回量)
// 概要 : 目標値と光センサの値(現在値)からPID制御値を算出
//=================================================================//
int pid_control(float kp, float ki, float kd, int target, int sensor_val, int pid_offset, int reset_i)
{
    static int nowd = 0, pastd = 0;
    static float tp, ti, td;
    int result = 0;

    //積分値リセット　区間ごとにtiの誤差が乗るから
    if (reset_i == 1)
    {
        ti = 0;
    }

    pastd = nowd;
    nowd = (sensor_val - target);

    /* P動作 */
    tp = kp * nowd;
    /* I動作 */
    ti += ki * ((nowd + pastd) / 2.0 * TIME);
    /* D動作 */
    td = kd * ((nowd - pastd) / TIME);

    result = (int)(tp + ti + td) + pid_offset;

    //飽和制御　turuの範囲は100~-100
    //(実機：127~-127)(シミュレータ：100~-100に自動変換（warning）)
    if (result > 100)
        result = 100;
    else if (result < -100)
        result = -100;
    //ラインの右、左エッジ
    if (_LEFT == 1)
    {
        result = -1.0 * result;
    }

    return result;
}
//*****************************************************************************
// 関数名 : tail_control
// 引数 : angle (モーター目標角度[度])
// 返り値 : 無し
// 概要 : 走行体完全停止用モーターの角度制御
//*****************************************************************************
static void arm_control(signed int angle)
{
    ev3_motor_set_power(arm_motor, -1 * (int32_t)(ev3_motor_get_counts(arm_motor) + angle));
}
