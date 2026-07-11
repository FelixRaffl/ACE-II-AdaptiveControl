/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: encoder_test.h
 *
 * Code generated for Simulink model 'encoder_test'.
 *
 * Model version                  : 1.1
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 16:24:20 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#ifndef encoder_test_h_
#define encoder_test_h_
#ifndef encoder_test_COMMON_INCLUDES_
#define encoder_test_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "rtw_extmode.h"
#include "sysran_types.h"
#include "rtw_continuous.h"
#include "rtw_solver.h"
#include "MW_ArduinoEncoder.h"
#include "MW_arduino_digitalio.h"
#include "MW_PWM.h"
#endif                                 /* encoder_test_COMMON_INCLUDES_ */

#include "encoder_test_types.h"
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
  real_T Counttodouble;                /* '<Root>/Count to double' */
  real_T DeltaN;                       /* '<Root>/Delta N' */
  real_T Countstorad_s;                /* '<Root>/Counts to rad_s' */
  real_T TmpSignalConversionAtTAQSigLogg[3];
  /* '<Root>/TmpSignal ConversionAtTAQSigLogging_InsertedFor_Bring-up mux_at_outport_0Inport1' */
} B_encoder_test_T;

/* Block states (default storage) for system '<Root>' */
typedef struct {
  codertarget_arduinobase_block_T obj; /* '<Root>/IN2 GPIO27' */
  codertarget_arduinobase_block_T obj_h;/* '<Root>/IN1 GPIO26' */
  codertarget_arduinobase_inter_T obj_l;/* '<Root>/Encoder' */
  codertarget_arduinobase_int_d_T obj_g;/* '<Root>/PWM GPIO14' */
  real_T N_prev_DSTATE;                /* '<Root>/N_prev' */
  struct {
    void *LoggedData[3];
  } Bringupscope_PWORK;                /* '<Root>/Bring-up scope' */
} DW_encoder_test_T;

/* Parameters (default storage) */
struct P_encoder_test_T_ {
  real_T N_prev_InitialCondition;      /* Expression: 0
                                        * Referenced by: '<Root>/N_prev'
                                        */
  real_T Countstorad_s_Gain;           /* Expression: 2*pi/(0.08*44)
                                        * Referenced by: '<Root>/Counts to rad_s'
                                        */
  real_T dir1_Value;                   /* Expression: 1
                                        * Referenced by: '<Root>/dir 1'
                                        */
  real_T dir0_Value;                   /* Expression: 0
                                        * Referenced by: '<Root>/dir 0'
                                        */
  real_T duty_Value;                   /* Expression: 0
                                        * Referenced by: '<Root>/duty'
                                        */
};

/* Real-time Model Data Structure */
struct tag_RTM_encoder_test_T {
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
extern P_encoder_test_T encoder_test_P;

/* Block signals (default storage) */
extern B_encoder_test_T encoder_test_B;

/* Block states (default storage) */
extern DW_encoder_test_T encoder_test_DW;

/* Model entry point functions */
extern void encoder_test_initialize(void);
extern void encoder_test_step(void);
extern void encoder_test_terminate(void);

/* Real-time Model object */
extern RT_MODEL_encoder_test_T *const encoder_test_M;
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
 * '<Root>' : 'encoder_test'
 */
#endif                                 /* encoder_test_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
