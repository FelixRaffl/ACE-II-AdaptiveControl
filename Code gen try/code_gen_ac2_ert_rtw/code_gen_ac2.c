/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: code_gen_ac2.c
 *
 * Code generated for Simulink model 'code_gen_ac2'.
 *
 * Model version                  : 1.9
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 16:12:43 2026
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
static void rate_monotonic_scheduler(void);

/*
 * Set which subrates need to run this base step (base rate always runs).
 * This function must be called prior to calling the model step function
 * in order to remember which rates need to run this base step.  The
 * buffering of events allows for overlapping preemption.
 */
void code_gen_ac2_SetEventsForThisBaseStep(boolean_T *eventFlags)
{
  /* Task runs when its counter is zero, computed via rtmStepTask macro */
  eventFlags[1] = ((boolean_T)rtmStepTask(code_gen_ac2_M, 1));
}

/*
 *         This function updates active task flag for each subrate
 *         and rate transition flags for tasks that exchange data.
 *         The function assumes rate-monotonic multitasking scheduler.
 *         The function must be called at model base rate so that
 *         the generated code self-manages all its subrates and rate
 *         transition flags.
 */
static void rate_monotonic_scheduler(void)
{
  /* Compute which subrates run during the next base time step.  Subrates
   * are an integer multiple of the base rate counter.  Therefore, the subtask
   * counter is reset when it reaches its limit (zero means run).
   */
  (code_gen_ac2_M->Timing.TaskCounters.TID[1])++;
  if ((code_gen_ac2_M->Timing.TaskCounters.TID[1]) > 15) {/* Sample time: [0.08s, 0.0s] */
    code_gen_ac2_M->Timing.TaskCounters.TID[1] = 0;
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

/* Model step function for TID0 */
void code_gen_ac2_step0(void)          /* Sample time: [0.005s, 0.0s] */
{
  {                                    /* Sample time: [0.005s, 0.0s] */
    rate_monotonic_scheduler();
  }

  /* Update absolute time */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   */
  code_gen_ac2_M->Timing.taskTime0 =
    ((time_T)(++code_gen_ac2_M->Timing.clockTick0)) *
    code_gen_ac2_M->Timing.stepSize0;
}

/* Model step function for TID1 */
void code_gen_ac2_step1(void)          /* Sample time: [0.08s, 0.0s] */
{
  real_T rtb_TSamp;
  real_T y;
  int32_T rtb_N_0;
  uint8_T tmp;

  /* SampleTimeMath: '<S1>/TSamp'
   *
   * About '<S1>/TSamp':
   *  y = u * K where K = 1 / ( w * Ts )
   *   */
  rtb_TSamp = 0.0 * code_gen_ac2_P.TSamp_WtEt;

  /* Gain: '<Root>/Gain' incorporates:
   *  Sum: '<S1>/Diff'
   *  UnitDelay: '<S1>/UD'
   *
   * Block description for '<S1>/Diff':
   *
   *  Add in CPU
   *
   * Block description for '<S1>/UD':
   *
   *  Store in Global RAM
   */
  code_gen_ac2_B.Gain = (rtb_TSamp - code_gen_ac2_DW.UD_DSTATE) *
    code_gen_ac2_P.Gain_Gain;

  /* DiscreteFilter: '<Root>/Discrete Filter' */
  code_gen_ac2_DW.DiscreteFilter_states = (code_gen_ac2_B.Gain -
    code_gen_ac2_P.DiscreteFilter_DenCoef[1] *
    code_gen_ac2_DW.DiscreteFilter_states) /
    code_gen_ac2_P.DiscreteFilter_DenCoef[0];

  /* DiscreteFilter: '<Root>/Discrete Filter' */
  code_gen_ac2_B.DiscreteFilter = code_gen_ac2_P.DiscreteFilter_NumCoef *
    code_gen_ac2_DW.DiscreteFilter_states;

  /* Constant: '<Root>/Constant' */
  code_gen_ac2_B.Constant = code_gen_ac2_P.Constant_Value;

  /* Sum: '<Root>/Sum' */
  code_gen_ac2_B.Sum = code_gen_ac2_B.Constant - code_gen_ac2_B.DiscreteFilter;

  /* MATLAB Function: '<Root>/MATLAB Function' incorporates:
   *  UnitDelay: '<Root>/Unit Delay'
   *  UnitDelay: '<Root>/Unit Delay1'
   */
  code_gen_ac2_DW.UnitDelay1_DSTATE += (code_gen_ac2_B.Sum -
    code_gen_ac2_DW.UnitDelay_DSTATE) * 0.05 + 0.2 * code_gen_ac2_B.Sum * 0.01;

  /* Saturate: '<Root>/Saturation' */
  if (code_gen_ac2_DW.UnitDelay1_DSTATE > code_gen_ac2_P.Saturation_UpperSat) {
    /* MATLAB Function: '<Root>/MATLAB Function' */
    code_gen_ac2_DW.UnitDelay1_DSTATE = code_gen_ac2_P.Saturation_UpperSat;
  } else if (code_gen_ac2_DW.UnitDelay1_DSTATE <
             code_gen_ac2_P.Saturation_LowerSat) {
    /* MATLAB Function: '<Root>/MATLAB Function' */
    code_gen_ac2_DW.UnitDelay1_DSTATE = code_gen_ac2_P.Saturation_LowerSat;
  }

  /* End of Saturate: '<Root>/Saturation' */
  /* MATLABSystem: '<Root>/PWM' */
  code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);

  /* Start for MATLABSystem: '<Root>/PWM' incorporates:
   *  Constant: '<Root>/Constant1'
   */
  if (code_gen_ac2_P.Constant1_Value <= 255.0) {
    y = code_gen_ac2_P.Constant1_Value;
  } else {
    y = 255.0;
  }

  if (!(y >= 0.0)) {
    y = 0.0;
  }

  /* MATLABSystem: '<Root>/PWM' */
  MW_PWM_SetDutyCycle(code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE, y);

  /* MATLABSystem: '<Root>/Digital Output' incorporates:
   *  Constant: '<Root>/Constant2'
   */
  y = rt_roundd_snf(code_gen_ac2_P.Constant2_Value);
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

  /* End of MATLABSystem: '<Root>/Digital Output' */

  /* MATLABSystem: '<Root>/Digital Output1' incorporates:
   *  Constant: '<Root>/Constant3'
   */
  y = rt_roundd_snf(code_gen_ac2_P.Constant3_Value);
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

  /* End of MATLABSystem: '<Root>/Digital Output1' */

  /* MATLABSystem: '<Root>/Encoder' */
  if (code_gen_ac2_DW.obj_n.TunablePropsChanged) {
    code_gen_ac2_DW.obj_n.TunablePropsChanged = false;
  }

  MW_EncoderRead(code_gen_ac2_DW.obj_n.Index, &rtb_N_0);

  /* Gain: '<Root>/Counts to rad_s' incorporates:
   *  DataTypeConversion: '<Root>/Count to double'
   *  MATLABSystem: '<Root>/Encoder'
   *  Sum: '<Root>/Delta N'
   *  UnitDelay: '<Root>/N_prev'
   */
  code_gen_ac2_B.omega = ((real_T)rtb_N_0 - code_gen_ac2_DW.N_prev_DSTATE) *
    code_gen_ac2_P.Countstorad_s_Gain;

  /* Update for UnitDelay: '<S1>/UD'
   *
   * Block description for '<S1>/UD':
   *
   *  Store in Global RAM
   */
  code_gen_ac2_DW.UD_DSTATE = rtb_TSamp;

  /* Update for UnitDelay: '<Root>/Unit Delay' */
  code_gen_ac2_DW.UnitDelay_DSTATE = code_gen_ac2_B.Sum;

  /* Update for UnitDelay: '<Root>/N_prev' incorporates:
   *  DataTypeConversion: '<Root>/Count to double'
   *  MATLABSystem: '<Root>/Encoder'
   */
  code_gen_ac2_DW.N_prev_DSTATE = rtb_N_0;

  /* Update absolute time */
  /* The "clockTick1" counts the number of times the code of this task has
   * been executed. The resolution of this integer timer is 0.08, which is the step size
   * of the task. Size of "clockTick1" ensures timer will not overflow during the
   * application lifespan selected.
   */
  code_gen_ac2_M->Timing.clockTick1++;
}

/* Use this function only if you need to maintain compatibility with an existing static main program. */
void code_gen_ac2_step(int_T tid)
{
  switch (tid) {
   case 0 :
    code_gen_ac2_step0();
    break;

   case 1 :
    code_gen_ac2_step1();
    break;

   default :
    /* do nothing */
    break;
  }
}

/* Model initialize function */
void code_gen_ac2_initialize(void)
{
  /* Registration code */
  rtmSetTFinal(code_gen_ac2_M, -1);
  code_gen_ac2_M->Timing.stepSize0 = 0.005;

  /* External mode info */
  code_gen_ac2_M->Sizes.checksums[0] = (1657719384U);
  code_gen_ac2_M->Sizes.checksums[1] = (769110667U);
  code_gen_ac2_M->Sizes.checksums[2] = (429143960U);
  code_gen_ac2_M->Sizes.checksums[3] = (4041905455U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[7];
    code_gen_ac2_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    systemRan[1] = &rtAlwaysEnabled;
    systemRan[2] = &rtAlwaysEnabled;
    systemRan[3] = &rtAlwaysEnabled;
    systemRan[4] = &rtAlwaysEnabled;
    systemRan[5] = &rtAlwaysEnabled;
    systemRan[6] = &rtAlwaysEnabled;
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

  /* InitializeConditions for DiscreteFilter: '<Root>/Discrete Filter' */
  code_gen_ac2_DW.DiscreteFilter_states =
    code_gen_ac2_P.DiscreteFilter_InitialStates;

  /* InitializeConditions for UnitDelay: '<Root>/Unit Delay' */
  code_gen_ac2_DW.UnitDelay_DSTATE = code_gen_ac2_P.UnitDelay_InitialCondition;

  /* InitializeConditions for MATLAB Function: '<Root>/MATLAB Function' incorporates:
   *  UnitDelay: '<Root>/Unit Delay1'
   */
  code_gen_ac2_DW.UnitDelay1_DSTATE = code_gen_ac2_P.UnitDelay1_InitialCondition;

  /* InitializeConditions for UnitDelay: '<Root>/N_prev' */
  code_gen_ac2_DW.N_prev_DSTATE = code_gen_ac2_P.N_prev_InitialCondition;

  /* Start for MATLABSystem: '<Root>/PWM' */
  code_gen_ac2_DW.obj_h.matlabCodegenIsDeleted = false;
  code_gen_ac2_DW.obj_h.isInitialized = 1;
  code_gen_ac2_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_Open(14U, 0.0, 0.0);
  code_gen_ac2_DW.obj_h.isSetupComplete = true;

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
