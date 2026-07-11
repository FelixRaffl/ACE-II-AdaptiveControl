/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: adaptive_dcmotor_data.c
 *
 * Code generated for Simulink model 'adaptive_dcmotor'.
 *
 * Model version                  : 1.2
 * Simulink Coder version         : 25.2 (R2025b) 28-Jul-2025
 * C/C++ source code generated on : Sat Jul 11 12:09:47 2026
 *
 * Target selection: ert.tlc
 * Embedded hardware selection: ARM Compatible->ARM Cortex
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "adaptive_dcmotor.h"

/* Block parameters (default storage) */
P_adaptive_dcmotor_T adaptive_dcmotor_P = {
  /* Mask Parameter: DiscreteDerivative_ICPrevScaled
   * Referenced by: '<S2>/UD'
   */
  0,

  /* Expression: [1]
   * Referenced by: '<Root>/Discrete Filter'
   */
  1.0,

  /* Expression: [1 0.5]
   * Referenced by: '<Root>/Discrete Filter'
   */
  { 1.0, 0.5 },

  /* Expression: 0
   * Referenced by: '<Root>/Discrete Filter'
   */
  0.0,

  /* Expression: 30
   * Referenced by: '<Root>/omega_ref'
   */
  30.0,

  /* Expression: 0
   * Referenced by: '<S1>/y_prev'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<S1>/u_prev'
   */
  0.0,

  /* Expression: 0.98
   * Referenced by: '<S1>/alpha'
   */
  0.98,

  /* Expression: 0.06
   * Referenced by: '<S1>/q0'
   */
  0.06,

  /* Expression: -0.5
   * Referenced by: '<S1>/q1'
   */
  -0.5,

  /* Expression: 0.001
   * Referenced by: '<S1>/b0 guard'
   */
  0.001,

  /* Expression: 0
   * Referenced by: '<S1>/e_prev'
   */
  0.0,

  /* Expression: 255
   * Referenced by: '<S1>/PWM saturation'
   */
  255.0,

  /* Expression: -255
   * Referenced by: '<S1>/PWM saturation'
   */
  -255.0,

  /* Computed Parameter: Gain_Gain
   * Referenced by: '<Root>/Gain'
   */
  1226017937
};

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
