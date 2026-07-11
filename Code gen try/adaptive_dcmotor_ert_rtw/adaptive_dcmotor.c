/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: adaptive_dcmotor.c
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

#include "adaptive_dcmotor.h"
#include <math.h>
#include "rtwtypes.h"
#include "adaptive_dcmotor_private.h"
#include "rt_nonfinite.h"

/* Block signals (default storage) */
B_adaptive_dcmotor_T adaptive_dcmotor_B;

/* Block states (default storage) */
DW_adaptive_dcmotor_T adaptive_dcmotor_DW;

/* Real-time model */
static RT_MODEL_adaptive_dcmotor_T adaptive_dcmotor_M_;
RT_MODEL_adaptive_dcmotor_T *const adaptive_dcmotor_M = &adaptive_dcmotor_M_;

/* Model step function */
void adaptive_dcmotor_step(void)
{
  real_T C_idx_0;
  real_T L_idx_0;
  real_T L_idx_1;
  real_T b_I;
  real_T b_I_0;
  real_T den;
  int32_T in2;

  /* MATLABSystem: '<Root>/Encoder' */
  if (adaptive_dcmotor_DW.obj_o.TunablePropsChanged) {
    adaptive_dcmotor_DW.obj_o.TunablePropsChanged = false;
  }

  MW_EncoderRead(adaptive_dcmotor_DW.obj_o.Index, &in2);

  /* DataTypeConversion: '<Root>/Count to double' incorporates:
   *  MATLABSystem: '<Root>/Encoder'
   */
  adaptive_dcmotor_B.Counttodouble = in2;

  /* Sum: '<Root>/Delta N' incorporates:
   *  UnitDelay: '<Root>/N_prev'
   */
  adaptive_dcmotor_B.DeltaN = adaptive_dcmotor_B.Counttodouble
    - adaptive_dcmotor_DW.N_prev_DSTATE;

  /* Gain: '<Root>/Counts to rad_s' */
  adaptive_dcmotor_B.omega = adaptive_dcmotor_P.Countstorad_s_Gain *
    adaptive_dcmotor_B.DeltaN;

  /* MATLAB Function: '<S1>/RLS Estimator' incorporates:
   *  Constant: '<S1>/alpha'
   *  UnitDelay: '<S1>/y_prev'
   */
  C_idx_0 = -adaptive_dcmotor_DW.y_prev_DSTATE;
  if (C_idx_0 * C_idx_0 + adaptive_dcmotor_DW.u_prev_DSTATE *
      adaptive_dcmotor_DW.u_prev_DSTATE > 1.0E-6) {
    L_idx_0 = C_idx_0 * adaptive_dcmotor_DW.P[0];
    L_idx_1 = adaptive_dcmotor_DW.u_prev_DSTATE * adaptive_dcmotor_DW.P[3];
    den = ((adaptive_dcmotor_DW.u_prev_DSTATE * adaptive_dcmotor_DW.P[1] +
            L_idx_0) * C_idx_0 + (C_idx_0 * adaptive_dcmotor_DW.P[2] + L_idx_1) *
           adaptive_dcmotor_DW.u_prev_DSTATE) + adaptive_dcmotor_P.alpha_Value;
    L_idx_0 = (adaptive_dcmotor_DW.P[2] * adaptive_dcmotor_DW.u_prev_DSTATE +
               L_idx_0) / den;
    L_idx_1 = (adaptive_dcmotor_DW.P[1] * C_idx_0 + L_idx_1) / den;
    den = adaptive_dcmotor_B.omega - (C_idx_0 * adaptive_dcmotor_DW.xe[0] +
      adaptive_dcmotor_DW.u_prev_DSTATE * adaptive_dcmotor_DW.xe[1]);
    adaptive_dcmotor_DW.xe[0] += L_idx_0 * den;
    adaptive_dcmotor_DW.xe[1] += L_idx_1 * den;
    adaptive_dcmotor_B.b_I[0] = 1.0 - L_idx_0 * C_idx_0;
    adaptive_dcmotor_B.b_I[1] = 0.0 - L_idx_1 * C_idx_0;
    adaptive_dcmotor_B.b_I[2] = 0.0 - L_idx_0 *
      adaptive_dcmotor_DW.u_prev_DSTATE;
    adaptive_dcmotor_B.b_I[3] = 1.0 - L_idx_1 *
      adaptive_dcmotor_DW.u_prev_DSTATE;
    C_idx_0 = adaptive_dcmotor_DW.P[1];
    L_idx_0 = adaptive_dcmotor_DW.P[0];
    L_idx_1 = adaptive_dcmotor_DW.P[3];
    den = adaptive_dcmotor_DW.P[2];
    for (in2 = 0; in2 < 2; in2++) {
      b_I = adaptive_dcmotor_B.b_I[in2 + 2];
      b_I_0 = adaptive_dcmotor_B.b_I[in2];
      adaptive_dcmotor_B.b_I_m[in2] = (b_I * C_idx_0 + b_I_0 * L_idx_0) /
        adaptive_dcmotor_P.alpha_Value;
      adaptive_dcmotor_B.b_I_m[in2 + 2] = (b_I * L_idx_1 + b_I_0 * den) /
        adaptive_dcmotor_P.alpha_Value;
    }

    adaptive_dcmotor_DW.P[0] = adaptive_dcmotor_B.b_I_m[0];
    adaptive_dcmotor_DW.P[1] = adaptive_dcmotor_B.b_I_m[1];
    adaptive_dcmotor_DW.P[2] = adaptive_dcmotor_B.b_I_m[2];
    adaptive_dcmotor_DW.P[3] = adaptive_dcmotor_B.b_I_m[3];
    C_idx_0 = (adaptive_dcmotor_DW.P[1] + adaptive_dcmotor_DW.P[2]) * 0.5;
    adaptive_dcmotor_DW.P[3] = (adaptive_dcmotor_DW.P[3] +
      adaptive_dcmotor_DW.P[3]) * 0.5;
    adaptive_dcmotor_DW.P[0] = (adaptive_dcmotor_DW.P[0] +
      adaptive_dcmotor_DW.P[0]) * 0.5;
    adaptive_dcmotor_DW.P[1] = C_idx_0;
    adaptive_dcmotor_DW.P[2] = C_idx_0;
  }

  adaptive_dcmotor_B.a0_est = adaptive_dcmotor_DW.xe[0];
  adaptive_dcmotor_B.b0_est = adaptive_dcmotor_DW.xe[1];
  adaptive_dcmotor_B.traceP = adaptive_dcmotor_DW.P[0] + adaptive_dcmotor_DW.P[3];

  /* End of MATLAB Function: '<S1>/RLS Estimator' */

  /* MATLAB Function: '<S1>/Pole placement' incorporates:
   *  Constant: '<S1>/b0 guard'
   *  Constant: '<S1>/q0'
   *  Constant: '<S1>/q1'
   */
  if (fabs(adaptive_dcmotor_B.b0_est) > adaptive_dcmotor_P.b0guard_Value) {
    adaptive_dcmotor_DW.d0Hold = (adaptive_dcmotor_P.q0_Value +
      adaptive_dcmotor_B.a0_est) / adaptive_dcmotor_B.b0_est;
    adaptive_dcmotor_DW.d1Hold = ((adaptive_dcmotor_P.q1_Value + 1.0) -
      adaptive_dcmotor_B.a0_est) / adaptive_dcmotor_B.b0_est;
  }

  /* DiscretePulseGenerator: '<Root>/Pulse Generator' */
  C_idx_0 = (adaptive_dcmotor_DW.clockTickCounter <
             adaptive_dcmotor_P.PulseGenerator_Duty) &&
    (adaptive_dcmotor_DW.clockTickCounter >= 0) ?
    adaptive_dcmotor_P.PulseGenerator_Amp : 0.0;
  if (adaptive_dcmotor_DW.clockTickCounter >=
      adaptive_dcmotor_P.PulseGenerator_Period - 1.0) {
    adaptive_dcmotor_DW.clockTickCounter = 0;
  } else {
    adaptive_dcmotor_DW.clockTickCounter++;
  }

  /* End of DiscretePulseGenerator: '<Root>/Pulse Generator' */

  /* ManualSwitch: '<Root>/Manual Switch' incorporates:
   *  Constant: '<Root>/omega_ref'
   */
  if (adaptive_dcmotor_P.ManualSwitch_CurrentSetting == 1) {
    C_idx_0 = adaptive_dcmotor_P.omega_ref_Value;
  }

  /* Gain: '<Root>/Gain' incorporates:
   *  ManualSwitch: '<Root>/Manual Switch'
   */
  adaptive_dcmotor_B.Gain = adaptive_dcmotor_P.Gain_Gain * C_idx_0;

  /* Sum: '<S1>/Tracking error' */
  adaptive_dcmotor_B.Trackingerror = adaptive_dcmotor_B.Gain -
    adaptive_dcmotor_B.omega;

  /* MATLAB Function: '<S1>/Incremental PI' incorporates:
   *  MATLAB Function: '<S1>/Pole placement'
   *  UnitDelay: '<S1>/e_prev'
   *  UnitDelay: '<S1>/u_prev'
   */
  adaptive_dcmotor_B.PWMsaturation = (adaptive_dcmotor_DW.d1Hold *
    adaptive_dcmotor_B.Trackingerror + adaptive_dcmotor_DW.u_prev_DSTATE) +
    adaptive_dcmotor_DW.d0Hold * adaptive_dcmotor_DW.e_prev_DSTATE;

  /* Saturate: '<S1>/PWM saturation' */
  if (adaptive_dcmotor_B.PWMsaturation >
      adaptive_dcmotor_P.PWMsaturation_UpperSat) {
    /* MATLAB Function: '<S1>/Incremental PI' incorporates:
     *  Saturate: '<S1>/PWM saturation'
     */
    adaptive_dcmotor_B.PWMsaturation = adaptive_dcmotor_P.PWMsaturation_UpperSat;
  } else if (adaptive_dcmotor_B.PWMsaturation <
             adaptive_dcmotor_P.PWMsaturation_LowerSat) {
    /* MATLAB Function: '<S1>/Incremental PI' incorporates:
     *  Saturate: '<S1>/PWM saturation'
     */
    adaptive_dcmotor_B.PWMsaturation = adaptive_dcmotor_P.PWMsaturation_LowerSat;
  }

  /* End of Saturate: '<S1>/PWM saturation' */

  /* MATLAB Function: '<Root>/H-bridge map' */
  if (adaptive_dcmotor_B.PWMsaturation >= 0.0) {
    adaptive_dcmotor_B.in1 = 1.0;
    in2 = 0;
  } else {
    adaptive_dcmotor_B.in1 = 0.0;
    in2 = 1;
  }

  /* SignalConversion generated from: '<Root>/Bring-up mux' */
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLogg[0] =
    adaptive_dcmotor_B.Counttodouble;
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLogg[1] =
    adaptive_dcmotor_B.DeltaN;
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLogg[2] =
    adaptive_dcmotor_B.omega;
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLogg[3] = adaptive_dcmotor_B.in1;

  /* SignalConversion generated from: '<Root>/a0b0 mux' */
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLo_m[0] =
    adaptive_dcmotor_B.a0_est;
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLo_m[1] =
    adaptive_dcmotor_B.b0_est;

  /* SignalConversion generated from: '<Root>/Tracking mux' */
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLo_j[0] =
    adaptive_dcmotor_B.Gain;
  adaptive_dcmotor_B.TmpSignalConversionAtTAQSigLo_j[1] =
    adaptive_dcmotor_B.omega;

  /* MATLABSystem: '<Root>/IN1 GPIO26' */
  writeDigitalPin(26, (uint8_T)adaptive_dcmotor_B.in1);

  /* MATLABSystem: '<Root>/IN2 GPIO27' */
  writeDigitalPin(27, (uint8_T)in2);

  /* MATLABSystem: '<Root>/PWM GPIO14' */
  adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle(14U);

  /* MATLAB Function: '<Root>/H-bridge map' */
  C_idx_0 = fabs(adaptive_dcmotor_B.PWMsaturation);

  /* Start for MATLABSystem: '<Root>/PWM GPIO14' */
  if (!(C_idx_0 <= 255.0)) {
    C_idx_0 = 255.0;
  }

  /* MATLABSystem: '<Root>/PWM GPIO14' */
  MW_PWM_SetDutyCycle(adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE,
                      C_idx_0);

  /* Update for UnitDelay: '<Root>/N_prev' */
  adaptive_dcmotor_DW.N_prev_DSTATE = adaptive_dcmotor_B.Counttodouble;

  /* Update for MATLAB Function: '<S1>/RLS Estimator' incorporates:
   *  UnitDelay: '<S1>/u_prev'
   */
  adaptive_dcmotor_DW.u_prev_DSTATE = adaptive_dcmotor_B.PWMsaturation;

  /* Update for UnitDelay: '<S1>/y_prev' */
  adaptive_dcmotor_DW.y_prev_DSTATE = adaptive_dcmotor_B.omega;

  /* Update for UnitDelay: '<S1>/e_prev' */
  adaptive_dcmotor_DW.e_prev_DSTATE = adaptive_dcmotor_B.Trackingerror;

  /* Update absolute time for base rate */
  /* The "clockTick0" counts the number of times the code of this task has
   * been executed. The absolute time is the multiplication of "clockTick0"
   * and "Timing.stepSize0". Size of "clockTick0" ensures timer will not
   * overflow during the application lifespan selected.
   */
  adaptive_dcmotor_M->Timing.taskTime0 =
    ((time_T)(++adaptive_dcmotor_M->Timing.clockTick0)) *
    adaptive_dcmotor_M->Timing.stepSize0;
}

/* Model initialize function */
void adaptive_dcmotor_initialize(void)
{
  /* Registration code */

  /* initialize non-finites */
  rt_InitInfAndNaN(sizeof(real_T));
  rtmSetTFinal(adaptive_dcmotor_M, -1);
  adaptive_dcmotor_M->Timing.stepSize0 = 0.08;

  /* External mode info */
  adaptive_dcmotor_M->Sizes.checksums[0] = (1665948789U);
  adaptive_dcmotor_M->Sizes.checksums[1] = (15937332U);
  adaptive_dcmotor_M->Sizes.checksums[2] = (3614204694U);
  adaptive_dcmotor_M->Sizes.checksums[3] = (3820503535U);

  {
    static const sysRanDType rtAlwaysEnabled = SUBSYS_RAN_BC_ENABLE;
    static RTWExtModeInfo rt_ExtModeInfo;
    static const sysRanDType *systemRan[9];
    adaptive_dcmotor_M->extModeInfo = (&rt_ExtModeInfo);
    rteiSetSubSystemActiveVectorAddresses(&rt_ExtModeInfo, systemRan);
    systemRan[0] = &rtAlwaysEnabled;
    systemRan[1] = &rtAlwaysEnabled;
    systemRan[2] = &rtAlwaysEnabled;
    systemRan[3] = &rtAlwaysEnabled;
    systemRan[4] = &rtAlwaysEnabled;
    systemRan[5] = &rtAlwaysEnabled;
    systemRan[6] = &rtAlwaysEnabled;
    systemRan[7] = &rtAlwaysEnabled;
    systemRan[8] = &rtAlwaysEnabled;
    rteiSetModelMappingInfoPtr(adaptive_dcmotor_M->extModeInfo,
      &adaptive_dcmotor_M->SpecialInfo.mappingInfo);
    rteiSetChecksumsPtr(adaptive_dcmotor_M->extModeInfo,
                        adaptive_dcmotor_M->Sizes.checksums);
    rteiSetTPtr(adaptive_dcmotor_M->extModeInfo, rtmGetTPtr(adaptive_dcmotor_M));
  }

  /* InitializeConditions for UnitDelay: '<Root>/N_prev' */
  adaptive_dcmotor_DW.N_prev_DSTATE = adaptive_dcmotor_P.N_prev_InitialCondition;

  /* InitializeConditions for MATLAB Function: '<S1>/RLS Estimator' incorporates:
   *  UnitDelay: '<S1>/u_prev'
   */
  adaptive_dcmotor_DW.u_prev_DSTATE = adaptive_dcmotor_P.u_prev_InitialCondition;

  /* InitializeConditions for UnitDelay: '<S1>/y_prev' */
  adaptive_dcmotor_DW.y_prev_DSTATE = adaptive_dcmotor_P.y_prev_InitialCondition;

  /* InitializeConditions for UnitDelay: '<S1>/e_prev' */
  adaptive_dcmotor_DW.e_prev_DSTATE = adaptive_dcmotor_P.e_prev_InitialCondition;

  /* SystemInitialize for MATLAB Function: '<S1>/RLS Estimator' */
  adaptive_dcmotor_DW.P[0] = 100.0;
  adaptive_dcmotor_DW.P[1] = 0.0;
  adaptive_dcmotor_DW.P[2] = 0.0;
  adaptive_dcmotor_DW.P[3] = 100.0;
  adaptive_dcmotor_DW.xe[0] = -0.5;
  adaptive_dcmotor_DW.xe[1] = 1.0;

  /* SystemInitialize for MATLAB Function: '<S1>/Pole placement' */
  adaptive_dcmotor_DW.d0Hold = -0.44;
  adaptive_dcmotor_DW.d1Hold = 1.0;

  /* Start for MATLABSystem: '<Root>/Encoder' */
  adaptive_dcmotor_DW.obj_o.Index = 0U;
  adaptive_dcmotor_DW.obj_o.matlabCodegenIsDeleted = false;
  adaptive_dcmotor_DW.obj_o.isSetupComplete = false;
  adaptive_dcmotor_DW.obj_o.isInitialized = 1;
  MW_EncoderSetup(32U, 33U, &adaptive_dcmotor_DW.obj_o.Index);
  adaptive_dcmotor_DW.obj_o.isSetupComplete = true;
  adaptive_dcmotor_DW.obj_o.TunablePropsChanged = false;

  /* InitializeConditions for MATLABSystem: '<Root>/Encoder' */
  MW_EncoderReset(adaptive_dcmotor_DW.obj_o.Index);

  /* Start for MATLABSystem: '<Root>/IN1 GPIO26' */
  adaptive_dcmotor_DW.obj_g.matlabCodegenIsDeleted = false;
  adaptive_dcmotor_DW.obj_g.isInitialized = 1;
  digitalIOSetup(26, 1);
  adaptive_dcmotor_DW.obj_g.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/IN2 GPIO27' */
  adaptive_dcmotor_DW.obj.matlabCodegenIsDeleted = false;
  adaptive_dcmotor_DW.obj.isInitialized = 1;
  digitalIOSetup(27, 1);
  adaptive_dcmotor_DW.obj.isSetupComplete = true;

  /* Start for MATLABSystem: '<Root>/PWM GPIO14' */
  adaptive_dcmotor_DW.obj_h.matlabCodegenIsDeleted = false;
  adaptive_dcmotor_DW.obj_h.isInitialized = 1;
  adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_Open(14U, 0.0,
    0.0);
  adaptive_dcmotor_DW.obj_h.isSetupComplete = true;
}

/* Model terminate function */
void adaptive_dcmotor_terminate(void)
{
  /* Terminate for MATLABSystem: '<Root>/Encoder' */
  if (!adaptive_dcmotor_DW.obj_o.matlabCodegenIsDeleted) {
    adaptive_dcmotor_DW.obj_o.matlabCodegenIsDeleted = true;
    if ((adaptive_dcmotor_DW.obj_o.isInitialized == 1) &&
        adaptive_dcmotor_DW.obj_o.isSetupComplete) {
      MW_EncoderRelease();
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/Encoder' */
  /* Terminate for MATLABSystem: '<Root>/IN1 GPIO26' */
  if (!adaptive_dcmotor_DW.obj_g.matlabCodegenIsDeleted) {
    adaptive_dcmotor_DW.obj_g.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/IN1 GPIO26' */

  /* Terminate for MATLABSystem: '<Root>/IN2 GPIO27' */
  if (!adaptive_dcmotor_DW.obj.matlabCodegenIsDeleted) {
    adaptive_dcmotor_DW.obj.matlabCodegenIsDeleted = true;
  }

  /* End of Terminate for MATLABSystem: '<Root>/IN2 GPIO27' */

  /* Terminate for MATLABSystem: '<Root>/PWM GPIO14' */
  if (!adaptive_dcmotor_DW.obj_h.matlabCodegenIsDeleted) {
    adaptive_dcmotor_DW.obj_h.matlabCodegenIsDeleted = true;
    if ((adaptive_dcmotor_DW.obj_h.isInitialized == 1) &&
        adaptive_dcmotor_DW.obj_h.isSetupComplete) {
      adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle
        (14U);
      MW_PWM_SetDutyCycle(adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE,
                          0.0);
      adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE = MW_PWM_GetHandle
        (14U);
      MW_PWM_Close(adaptive_dcmotor_DW.obj_h.PWMDriverObj.MW_PWM_HANDLE);
    }
  }

  /* End of Terminate for MATLABSystem: '<Root>/PWM GPIO14' */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
