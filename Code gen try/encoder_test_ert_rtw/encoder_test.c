/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: encoder_test.c
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

#include "encoder_test.h"
#include "encoder_test_private.h"
#include "rtwtypes.h"
#include <math.h>

/* Block signals (default storage) */
B_encoder_test_T encoder_test_B;

/* Block states (default storage) */
DW_encoder_test_T encoder_test_DW;

/* Real-time model */
static RT_MODEL_encoder_test_T encoder_test_M_;
RT_MODEL_encoder_test_T *const encoder_test_M = &encoder_test_M_;
real_T rt_roundd_snf(real_T u)
{
  real_T y;
  if (fabs(u) < 4.503599627370496E+15) {
    if (u >= 0.5) {
      y = floor(u + 0.5);
    } else if (u > -0.5) {
      y = u * 0.0;
    } else {
      y = ceil(u - 0.5);
    }
  } else {
    y = u;
  }

  return y;
}

/* Model step function */
void encoder_test_step(void)
{
  real_T y;
  int32_T rtb_N_0;
  uint8_T tmp;

  /* MATLABSystem: '<Root>/Encoder' */
  if (encoder_test_DW.obj_l.TunablePropsChanged) {
    encoder_test_DW.obj_l.TunablePropsChanged = false;
  }

  MW_EncoderRead(encoder_test_DW.obj_l.Index, &rtb_N_0);

  /* DataTypeConversion: '<Root>/Count to double' incorporates:
   *  MATLABSystem: '<Root>/Encoder'
   */
  encoder_test_B.Counttodouble = rtb_N_0;

  /* Sum: '<Root>/Delta N' incorporates:
   *  UnitDelay: '<Root>/N_prev'
   */
  encoder_test_B.DeltaN = encoder_test_B.Counttodouble
    - encoder_test_DW.N_prev_DSTATE;

  /* Gain: '<Root>/Counts to rad_s' */
  encoder_test_B.Countstorad_s = encoder_test_P.Countstorad_s_Gain *
    encoder_test_B.DeltaN;

  /* SignalConversion generated from: '<Root>/Bring-up mux' */
  encoder_test_B.TmpSignalConversionAtTAQSigLogg[0] =
    encoder_test_B.Counttodouble;
  encoder_test_B.TmpSignalConversionAtTAQSigLogg[1] = encoder_test_B.DeltaN;
  encoder_test_B.TmpSignalConversionAtTAQSigLogg[2] =
    encoder_test_B.Countstorad_s;

  /* MATLABSystem: '<Root>/IN1 GPIO26' incorporates:
   *  Constant: '<Root>/dir 1'
   */
  y = rt_roundd_snf(encoder_test_P.dir1_Value);
  if (y < 256.0) {
    if (y >= 0.0) {
      tmp = (uint8_T)y;
    } else {
      tmp = 0U;
    }
  } else {
    tmp = MAX_uint8_T;
  }

  writeDigitalPin(26, tmp);

  /* End of MATLABSystem: '<Root>/IN1 GPIO26' */

  /* MATLABSystem: '<Root>/IN2 GPIO27' incorporates:
   *  Constant: '<Root>/dir 0'
   */
  y = rt_roundd_snf(encoder_test_P.dir0_Value);
  if (y < 256.0) {
    if (y >= 0.0) {
      tmp = (uint8_T)y;
    } else {
      tmp = 0U;
    }
  } else {
    tmp = MAX_uint8_T;
  }

  writeDigitalPin(27, tmp);

  /* End of MATLABSystem: '<Root>/IN2 GPIO27' */

  /* MATLABSystem: '<Root>/PWM GPIO14' */
  encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);

  /* Start for MATLABSystem: '<Root>/PWM GPIO14' incorporates:
   *  Constant: '<Root>/duty'
   */
  if (encoder_test_P.duty_Value <= 255.0) {
    y = encoder_test_P.duty_Value;
  } else {
    y = 255.0;
  }

  if (!(y >= 0.0)) {
    y = 0.0;
  }

  /* MATLABSystem: '<Root>/PWM GPIO14' */
  MW_PWM_SetDutyCycle(encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE, y);

  /* Update for UnitDelay: '<Root>/N_prev' */
  encoder_test_DW.N_prev_DSTATE = encoder_test_B.Counttodouble;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   */
  encoder_test_M->Timing.taskTime0 =
    ((time_T)(++encoder_test_M->Timing.clockTick0)) *
    encoder_test_M->Timing.stepSize0;
}

/* Model initialize function */
void encoder_test_initialize(void)
{
  /* Registration code */
  rtmSetTFinal(encoder_test_M, -1);
  encoder_test_M->Timing.stepSize0 = 0.08;

  /* External mode info */
  encoder_test_M->Sizes.checksums[0] = (531814197U);
  encoder_test_M->Sizes.checksums[1] = (1028152317U);
  encoder_test_M->Sizes.checksums[2] = (632692370U);
  encoder_test_M->Sizes.checksums[3] = (1015081760U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[5];
    encoder_test_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    systemRan[1] = &rtAlwaysEnabled;
    systemRan[2] = &rtAlwaysEnabled;
    systemRan[3] = &rtAlwaysEnabled;
    systemRan[4] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr(encoder_test_M->extModeInfo,
      &encoder_test_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr(encoder_test_M->extModeInfo,
                        encoder_test_M->Sizes.checksums);
    rteiSetTPtr(encoder_test_M->extModeInfo, rtmGetTPtr(encoder_test_M));
  }

  /* InitializeConditions for UnitDelay: '<Root>/N_prev' */
  encoder_test_DW.N_prev_DSTATE = encoder_test_P.N_prev_InitialCondition;

  /* Start for MATLABSystem: '<Root>/Encoder' */
  encoder_test_DW.obj_l.Index = 0U;
  encoder_test_DW.obj_l.matlabCodegenIsDeleted = false;
  encoder_test_DW.obj_l.isSetupComplete = false;
  encoder_test_DW.obj_l.isInitialized = 1;
  MW_EncoderSetup(32U, 33U, &encoder_test_DW.obj_l.Index);
  encoder_test_DW.obj_l.isSetupComplete = true;
  encoder_test_DW.obj_l.TunablePropsChanged = false;

  /* InitializeConditions for MATLABSystem: '<Root>/Encoder' */
  MW_EncoderReset(encoder_test_DW.obj_l.Index);

  /* Start for MATLABSystem: '<Root>/IN1 GPIO26' */
  encoder_test_DW.obj_h.matlabCodegenIsDeleted = false;
  encoder_test_DW.obj_h.isInitialized = 1;
  digitalIOSetup(26, 1);
  encoder_test_DW.obj_h.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/IN2 GPIO27' */
  encoder_test_DW.obj.matlabCodegenIsDeleted = false;
  encoder_test_DW.obj.isInitialized = 1;
  digitalIOSetup(27, 1);
  encoder_test_DW.obj.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/PWM GPIO14' */
  encoder_test_DW.obj_g.matlabCodegenIsDeleted = false;
  encoder_test_DW.obj_g.isInitialized = 1;
  encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_Open(14U, 0.0, 0.0);
  encoder_test_DW.obj_g.isSetupComplete = true;
}

/* Model terminate function */
void encoder_test_terminate(void)
{
  /* Terminate for MATLABSystem: '<Root>/Encoder' */
  if (!encoder_test_DW.obj_l.matlabCodegenIsDeleted) {
    encoder_test_DW.obj_l.matlabCodegenIsDeleted = true;
    if ((encoder_test_DW.obj_l.isInitialized == 1) &&
        encoder_test_DW.obj_l.isSetupComplete) {
      MW_EncoderRelease();
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/Encoder' */
  /* Terminate for MATLABSystem: '<Root>/IN1 GPIO26' */
  if (!encoder_test_DW.obj_h.matlabCodegenIsDeleted) {
    encoder_test_DW.obj_h.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/IN1 GPIO26' */

  /* Terminate for MATLABSystem: '<Root>/IN2 GPIO27' */
  if (!encoder_test_DW.obj.matlabCodegenIsDeleted) {
    encoder_test_DW.obj.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/IN2 GPIO27' */

  /* Terminate for MATLABSystem: '<Root>/PWM GPIO14' */
  if (!encoder_test_DW.obj_g.matlabCodegenIsDeleted) {
    encoder_test_DW.obj_g.matlabCodegenIsDeleted = true;
    if ((encoder_test_DW.obj_g.isInitialized == 1) &&
        encoder_test_DW.obj_g.isSetupComplete) {
      encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);
      MW_PWM_SetDutyCycle(encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE, 0.0);
      encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);
      MW_PWM_Close(encoder_test_DW.obj_g.PWMDriverObj.MW_PWM_HANDLE);
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/PWM GPIO14' */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
