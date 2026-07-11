/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: code_gen_ac2.c
 *
 * Code generated for Simulink model 'code_gen_ac2'.
 *
 * Model version                  : 1.8
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 10:55:01 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "code_gen_ac2.h"
#include "code_gen_ac2_private.h"
#include "rtwtypes.h"
#include <math.h>

/* Block signals (default storage) */
B_code_gen_ac2_T code_gen_ac2_B;

/* Block states (default storage) */
DW_code_gen_ac2_T code_gen_ac2_DW;

/* Real-time model */
static RT_MODEL_code_gen_ac2_T code_gen_ac2_M_;
RT_MODEL_code_gen_ac2_T *const code_gen_ac2_M = &code_gen_ac2_M_;
void sMultiWordMul(const uint32_T u1[], int32_T n1, const uint32_T u2[], int32_T
                   n2, uint32_T y[], int32_T n)
{
  int32_T i;
  int32_T j;
  int32_T k;
  int32_T ni;
  uint32_T a0;
  uint32_T a1;
  uint32_T b1;
  uint32_T cb;
  uint32_T cb1;
  uint32_T cb2;
  uint32_T u1i;
  uint32_T w01;
  uint32_T w10;
  uint32_T yk;
  boolean_T isNegative1;
  boolean_T isNegative2;
  isNegative1 = ((u1[n1 - 1] & 2147483648U) != 0U);
  isNegative2 = ((u2[n2 - 1] & 2147483648U) != 0U);
  cb1 = 1U;

  /* Initialize output to zero */
  for (k = 0; k < n; k++) {
    y[k] = 0U;
  }

  for (i = 0; i < n1; i++) {
    cb = 0U;
    u1i = u1[i];
    if (isNegative1) {
      u1i = ~u1i + cb1;
      cb1 = (uint32_T)(u1i < cb1);
    }

    a1 = u1i >> 16U;
    a0 = u1i & 65535U;
    cb2 = 1U;
    ni = n - i;
    ni = n2 <= ni ? n2 : ni;
    k = i;
    for (j = 0; j < ni; j++) {
      u1i = u2[j];
      if (isNegative2) {
        u1i = ~u1i + cb2;
        cb2 = (uint32_T)(u1i < cb2);
      }

      b1 = u1i >> 16U;
      u1i &= 65535U;
      w10 = a1 * u1i;
      w01 = a0 * b1;
      yk = y[k] + cb;
      cb = (uint32_T)(yk < cb);
      u1i *= a0;
      yk += u1i;
      cb += (uint32_T)(yk < u1i);
      u1i = w10 << 16U;
      yk += u1i;
      cb += (uint32_T)(yk < u1i);
      u1i = w01 << 16U;
      yk += u1i;
      cb += (uint32_T)(yk < u1i);
      y[k] = yk;
      cb += w10 >> 16U;
      cb += w01 >> 16U;
      cb += a1 * b1;
      k++;
    }

    if (k < n) {
      y[k] = cb;
    }
  }

  /* Apply sign */
  if (isNegative1 != isNegative2) {
    cb = 1U;
    for (k = 0; k < n; k++) {
      yk = ~y[k] + cb;
      y[k] = yk;
      cb = (uint32_T)(yk < cb);
    }
  }
}

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
void code_gen_ac2_step(void)
{
  real_T y;
  uint32_T tmp;
  uint32_T tmp_0;
  uint8_T tmp_1;

  /* MATLABSystem: '<Root>/Digital Output' incorporates:
   *  Constant: '<Root>/Constant'
   */
  y = rt_roundd_snf(code_gen_ac2_P.Constant_Value);
  if (y < 256.0) {
    if (y >= 0.0) {
      tmp_1 = (uint8_T)y;
    } else {
      tmp_1 = 0U;
    }
  } else {
    tmp_1 = MAX_uint8_T;
  }

  writeDigitalPin(27, tmp_1);

  /* End of MATLABSystem: '<Root>/Digital Output' */

  /* MATLABSystem: '<Root>/Digital Output1' incorporates:
   *  Constant: '<Root>/Constant1'
   */
  y = rt_roundd_snf(code_gen_ac2_P.Constant1_Value);
  if (y < 256.0) {
    if (y >= 0.0) {
      tmp_1 = (uint8_T)y;
    } else {
      tmp_1 = 0U;
    }
  } else {
    tmp_1 = MAX_uint8_T;
  }

  writeDigitalPin(26, tmp_1);

  /* End of MATLABSystem: '<Root>/Digital Output1' */

  /* MATLABSystem: '<Root>/PWM' */
  code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);

  /* Start for MATLABSystem: '<Root>/PWM' incorporates:
   *  Constant: '<Root>/Constant2'
   */
  if (code_gen_ac2_P.Constant2_Value <= 255.0) {
    y = code_gen_ac2_P.Constant2_Value;
  } else {
    y = 255.0;
  }

  if (!(y >= 0.0)) {
    y = 0.0;
  }

  /* MATLABSystem: '<Root>/PWM' */
  MW_PWM_SetDutyCycle(code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE, y);

  /* MATLABSystem: '<Root>/Encoder' */
  if (code_gen_ac2_DW.obj_n.TunablePropsChanged) {
    code_gen_ac2_DW.obj_n.TunablePropsChanged = false;
  }

  /* MATLABSystem: '<Root>/Encoder' */
  MW_EncoderRead(code_gen_ac2_DW.obj_n.Index, &code_gen_ac2_B.Encoder);

  /* Gain: '<Root>/Gain' incorporates:
   *  SampleTimeMath: '<S1>/TSamp'
   *  Sum: '<S1>/Diff'
   *  UnitDelay: '<S1>/UD'
   *
   * About '<S1>/TSamp':
   *  y = u * K where K = 1 / ( w * Ts )
   *  Multiplication by K = weightedTsampQuantized is being
   *  done implicitly by changing the scaling of the input signal.
   *  No work needs to be done here.  Downstream blocks may need
   *  to do work to handle the scaling of the output; this happens
   *  automatically.
   *   *
   * Block description for '<S1>/Diff':
   *
   *  Add in CPU
   *
   * Block description for '<S1>/UD':
   *
   *  Store in Global RAM
   */
  tmp = (uint32_T)code_gen_ac2_P.Gain_Gain;
  tmp_0 = (uint32_T)(code_gen_ac2_B.Encoder - code_gen_ac2_DW.UD_DSTATE);
  sMultiWordMul(&tmp, 1, &tmp_0, 1, &code_gen_ac2_B.Gain.chunks[0U], 2);

  /* Update for UnitDelay: '<S1>/UD' incorporates:
   *  SampleTimeMath: '<S1>/TSamp'
   *
   * About '<S1>/TSamp':
   *  y = u * K where K = 1 / ( w * Ts )
   *  Multiplication by K = weightedTsampQuantized is being
   *  done implicitly by changing the scaling of the input signal.
   *  No work needs to be done here.  Downstream blocks may need
   *  to do work to handle the scaling of the output; this happens
   *  automatically.
   *   *
   * Block description for '<S1>/UD':
   *
   *  Store in Global RAM
   */
  code_gen_ac2_DW.UD_DSTATE = code_gen_ac2_B.Encoder;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   */
  code_gen_ac2_M->Timing.taskTime0 =
    ((time_T)(++code_gen_ac2_M->Timing.clockTick0)) *
    code_gen_ac2_M->Timing.stepSize0;
}

/* Model initialize function */
void code_gen_ac2_initialize(void)
{
  /* Registration code */
  rtmSetTFinal(code_gen_ac2_M, -1);
  code_gen_ac2_M->Timing.stepSize0 = 0.005;

  /* External mode info */
  code_gen_ac2_M->Sizes.checksums[0] = (3196013304U);
  code_gen_ac2_M->Sizes.checksums[1] = (2808726728U);
  code_gen_ac2_M->Sizes.checksums[2] = (875356809U);
  code_gen_ac2_M->Sizes.checksums[3] = (2387687511U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[5];
    code_gen_ac2_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    systemRan[1] = &rtAlwaysEnabled;
    systemRan[2] = &rtAlwaysEnabled;
    systemRan[3] = &rtAlwaysEnabled;
    systemRan[4] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr(code_gen_ac2_M->extModeInfo,
      &code_gen_ac2_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr(code_gen_ac2_M->extModeInfo,
                        code_gen_ac2_M->Sizes.checksums);
    rteiSetTPtr(code_gen_ac2_M->extModeInfo, rtmGetTPtr(code_gen_ac2_M));
  }

  /* InitializeConditions for UnitDelay: '<S1>/UD'
   *
   * Block description for '<S1>/UD':
   *
   *  Store in Global RAM
   */
  code_gen_ac2_DW.UD_DSTATE = code_gen_ac2_P.DiscreteDerivative_ICPrevScaled;

  /* Start for MATLABSystem: '<Root>/Digital Output' */
  code_gen_ac2_DW.obj_p.matlabCodegenIsDeleted = false;
  code_gen_ac2_DW.obj_p.isInitialized = 1;
  digitalIOSetup(27, 1);
  code_gen_ac2_DW.obj_p.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/Digital Output1' */
  code_gen_ac2_DW.obj.matlabCodegenIsDeleted = false;
  code_gen_ac2_DW.obj.isInitialized = 1;
  digitalIOSetup(26, 1);
  code_gen_ac2_DW.obj.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/PWM' */
  code_gen_ac2_DW.obj_h.matlabCodegenIsDeleted = false;
  code_gen_ac2_DW.obj_h.isInitialized = 1;
  code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_Open(14U, 0.0, 0.0);
  code_gen_ac2_DW.obj_h.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/Encoder' */
  code_gen_ac2_DW.obj_n.Index = 0U;
  code_gen_ac2_DW.obj_n.matlabCodegenIsDeleted = false;
  code_gen_ac2_DW.obj_n.isSetupComplete = false;
  code_gen_ac2_DW.obj_n.isInitialized = 1;
  MW_EncoderSetup(32U, 33U, &code_gen_ac2_DW.obj_n.Index);
  code_gen_ac2_DW.obj_n.isSetupComplete = true;
  code_gen_ac2_DW.obj_n.TunablePropsChanged = false;

  /* InitializeConditions for MATLABSystem: '<Root>/Encoder' */
  MW_EncoderReset(code_gen_ac2_DW.obj_n.Index);
}

/* Model terminate function */
void code_gen_ac2_terminate(void)
{
  /* Terminate for MATLABSystem: '<Root>/Digital Output' */
  if (!code_gen_ac2_DW.obj_p.matlabCodegenIsDeleted) {
    code_gen_ac2_DW.obj_p.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/Digital Output' */

  /* Terminate for MATLABSystem: '<Root>/Digital Output1' */
  if (!code_gen_ac2_DW.obj.matlabCodegenIsDeleted) {
    code_gen_ac2_DW.obj.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/Digital Output1' */

  /* Terminate for MATLABSystem: '<Root>/PWM' */
  if (!code_gen_ac2_DW.obj_h.matlabCodegenIsDeleted) {
    code_gen_ac2_DW.obj_h.matlabCodegenIsDeleted = true;
    if ((code_gen_ac2_DW.obj_h.isInitialized == 1) &&
        code_gen_ac2_DW.obj_h.isSetupComplete) {
      code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);
      MW_PWM_SetDutyCycle(code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE, 0.0);
      code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);
      MW_PWM_Close(code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE);
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/PWM' */

  /* Terminate for MATLABSystem: '<Root>/Encoder' */
  if (!code_gen_ac2_DW.obj_n.matlabCodegenIsDeleted) {
    code_gen_ac2_DW.obj_n.matlabCodegenIsDeleted = true;
    if ((code_gen_ac2_DW.obj_n.isInitialized == 1) &&
        code_gen_ac2_DW.obj_n.isSetupComplete) {
      MW_EncoderRelease();
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/Encoder' */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
