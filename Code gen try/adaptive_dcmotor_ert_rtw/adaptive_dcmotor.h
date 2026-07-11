/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: adaptive_dcmotor.h
 *
 * Code generated for Simulink model 'adaptive_dcmotor'.
 *
 * Model version                  : 1.1
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 17:07:29 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef adaptive_dcmotor_h_
#define adaptive_dcmotor_h_
#ifndef adaptive_dcmotor_COMMON_INCLUDES_
#define adaptive_dcmotor_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "rtw_extmode.h"
#include "sysran_types.h"
#include "rtw_continuous.h"
#include "rtw_solver.h"
#include "MW_ArduinoEncoder.h"
#include "MW_arduino_digitalio.h"
#include "MW_PWM.h"
#endif                                 /* adaptive_dcmotor_COMMON_INCLUDES_ */

#include "adaptive_dcmotor_types.h"
#include "rt_nonfinite.h"
#include <stddef.h>

/* Macros for accessing real-time model data structure */
#ifndef rtmGetFinalTime
#define rtmGetFinalTime(rtm)           ((rtm)->Timing.tFinal)
#endif

#ifndef rtmGetRTWExtModeInfo
#define rtmGetRTWExtModeInfo(rtm)      ((rtm)->extModeInfo)
#endif

#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

#ifndef rtmGetStopRequested
#define rtmGetStopRequested(rtm)       ((rtm)->Timing.stopRequestedFlag)
#endif

#ifndef rtmSetStopRequested
#define rtmSetStopRequested(rtm, val)  ((rtm)->Timing.stopRequestedFlag = (val))
#endif

#ifndef rtmGetStopRequestedPtr
#define rtmGetStopRequestedPtr(rtm)    (&((rtm)->Timing.stopRequestedFlag))
#endif

#ifndef rtmGetT
#define rtmGetT(rtm)                   ((rtm)->Timing.taskTime0)
#endif

#ifndef rtmGetTFinal
#define rtmGetTFinal(rtm)              ((rtm)->Timing.tFinal)
#endif

#ifndef rtmGetTPtr
#define rtmGetTPtr(rtm)                (&(rtm)->Timing.taskTime0)
#endif

/* Block signals (default storage) */
typedef struct {
  real_T b_I[4];
  real_T b_I_m[4];
  real_T Counttodouble;                /* '<Root>/Count to double' */
  real_T DeltaN;                       /* '<Root>/Delta N' */
  real_T omega;                        /* '<Root>/Counts to rad_s' */
  real_T Gain;                         /* '<Root>/Gain' */
  real_T Trackingerror;                /* '<S1>/Tracking error' */
  real_T PWMsaturation;                /* '<S1>/PWM saturation' */
  real_T TmpSignalConversionAtTAQSigLogg[4];
  /* '<Root>/TmpSignal ConversionAtTAQSigLogging_InsertedFor_Bring-up mux_at_outport_0Inport1' */
  real_T TmpSignalConversionAtTAQSigLo_m[2];
  /* '<Root>/TmpSignal ConversionAtTAQSigLogging_InsertedFor_a0b0 mux_at_outport_0Inport1' */
  real_T TmpSignalConversionAtTAQSigLo_j[2];
  /* '<Root>/TmpSignal ConversionAtTAQSigLogging_InsertedFor_Tracking mux_at_outport_0Inport1' */
  real_T in1;                          /* '<Root>/H-bridge map' */
  real_T a0_est;                       /* '<S1>/RLS Estimator' */
  real_T b0_est;                       /* '<S1>/RLS Estimator' */
  real_T traceP;                       /* '<S1>/RLS Estimator' */
} B_adaptive_dcmotor_T;

/* Block states (default storage) for system '<Root>' */
typedef struct {
  codertarget_arduinobase_block_T obj; /* '<Root>/IN2 GPIO27' */
  codertarget_arduinobase_block_T obj_g;/* '<Root>/IN1 GPIO26' */
  codertarget_arduinobase_inter_T obj_o;/* '<Root>/Encoder' */
  codertarget_arduinobase_int_k_T obj_h;/* '<Root>/PWM GPIO14' */
  real_T N_prev_DSTATE;                /* '<Root>/N_prev' */
  real_T u_prev_DSTATE;                /* '<S1>/u_prev' */
  real_T y_prev_DSTATE;                /* '<S1>/y_prev' */
  real_T e_prev_DSTATE;                /* '<S1>/e_prev' */
  real_T P[4];                         /* '<S1>/RLS Estimator' */
  real_T xe[2];                        /* '<S1>/RLS Estimator' */
  real_T d0Hold;                       /* '<S1>/Pole placement' */
  real_T d1Hold;                       /* '<S1>/Pole placement' */
  struct {
    void *LoggedData[4];
  } Bringupscope_PWORK;                /* '<Root>/Bring-up scope' */

  struct {
    void *LoggedData[4];
  } Adaptationscope_PWORK;             /* '<Root>/Adaptation scope' */

  struct {
    void *LoggedData;
  } Trackingscope_PWORK;               /* '<Root>/Tracking scope' */

  int32_T clockTickCounter;            /* '<Root>/Pulse Generator' */
  boolean_T doneDoubleBufferReInit;    /* '<Root>/H-bridge map' */
  boolean_T doneDoubleBufferReInit_l;  /* '<S1>/RLS Estimator' */
  boolean_T doneDoubleBufferReInit_e;  /* '<S1>/Pole placement' */
  boolean_T doneDoubleBufferReInit_lb; /* '<S1>/Incremental PI' */
} DW_adaptive_dcmotor_T;

/* Parameters (default storage) */
struct P_adaptive_dcmotor_T_ {
  real_T N_prev_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<Root>/N_prev'
                                        */
  real_T Countstorad_s_Gain;           /* Expression: 2*pi/(0.08*44)
                                        * Referenced by: '<Root>/Counts to rad_s'
                                        */
  real_T u_prev_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<S1>/u_prev'
                                        */
  real_T y_prev_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<S1>/y_prev'
                                        */
  real_T alpha_Value;                  /* Expression: 0.98
                                        * Referenced by: '<S1>/alpha'
                                        */
  real_T q0_Value;                     /* Expression: 0.06
                                        * Referenced by: '<S1>/q0'
                                        */
  real_T q1_Value;                     /* Expression: -0.5
                                        * Referenced by: '<S1>/q1'
                                        */
  real_T b0guard_Value;                /* Expression: 0.001
                                        * Referenced by: '<S1>/b0 guard'
                                        */
  real_T omega_ref_Value;              /* Expression: 255
                                        * Referenced by: '<Root>/omega_ref'
                                        */
  real_T PulseGenerator_Amp;           /* Expression: 255
                                        * Referenced by: '<Root>/Pulse Generator'
                                        */
  real_T PulseGenerator_Period;     /* Computed Parameter: PulseGenerator_Period
                                     * Referenced by: '<Root>/Pulse Generator'
                                     */
  real_T PulseGenerator_Duty;         /* Computed Parameter: PulseGenerator_Duty
                                       * Referenced by: '<Root>/Pulse Generator'
                                       */
  real_T PulseGenerator_PhaseDelay;    /* Expression: 0
                                        * Referenced by: '<Root>/Pulse Generator'
                                        */
  real_T Gain_Gain;                    /* Expression: 780/255
                                        * Referenced by: '<Root>/Gain'
                                        */
  real_T e_prev_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<S1>/e_prev'
                                        */
  real_T PWMsaturation_UpperSat;       /* Expression: 255
                                        * Referenced by: '<S1>/PWM saturation'
                                        */
  real_T PWMsaturation_LowerSat;       /* Expression: 0
                                        * Referenced by: '<S1>/PWM saturation'
                                        */
  uint8_T ManualSwitch_CurrentSetting;
                              /* Computed Parameter: ManualSwitch_CurrentSetting
                               * Referenced by: '<Root>/Manual Switch'
                               */
};

/* Real-time Model Data Structure */
struct tag_RTM_adaptive_dcmotor_T {
  const char_T *errorStatus;
  RTWExtModeInfo *extModeInfo;

  /*
   * Sizes:
   * The following substructure contains sizes information
   * for many of the model attributes such as inputs, outputs,
   * dwork, sample times, etc.
   */
  struct {
    uint32_T checksums[4];
  } Sizes;

  /*
   * SpecialInfo:
   * The following substructure contains special information
   * related to other components that are dependent on RTW.
   */
  struct {
    const void *mappingInfo;
  } SpecialInfo;

  /*
   * Timing:
   * The following substructure contains information regarding
   * the timing information for the model.
   */
  struct {
    time_T taskTime0;
    uint32_T clockTick0;
    time_T stepSize0;
    time_T tFinal;
    boolean_T stopRequestedFlag;
  } Timing;
};

/* Block parameters (default storage) */
extern P_adaptive_dcmotor_T adaptive_dcmotor_P;

/* Block signals (default storage) */
extern B_adaptive_dcmotor_T adaptive_dcmotor_B;

/* Block states (default storage) */
extern DW_adaptive_dcmotor_T adaptive_dcmotor_DW;

/* Model entry point functions */
extern void adaptive_dcmotor_initialize(void);
extern void adaptive_dcmotor_step(void);
extern void adaptive_dcmotor_terminate(void);

/* Real-time Model object */
extern RT_MODEL_adaptive_dcmotor_T *const adaptive_dcmotor_M;
extern volatile boolean_T stopRequested;
extern volatile boolean_T runModel;

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'adaptive_dcmotor'
 * '<S1>'   : 'adaptive_dcmotor/Adaptive controller'
 * '<S2>'   : 'adaptive_dcmotor/H-bridge map'
 * '<S3>'   : 'adaptive_dcmotor/Adaptive controller/Incremental PI'
 * '<S4>'   : 'adaptive_dcmotor/Adaptive controller/Pole placement'
 * '<S5>'   : 'adaptive_dcmotor/Adaptive controller/RLS Estimator'
 */
#endif                                 /* adaptive_dcmotor_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
