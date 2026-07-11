/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: code_gen_ac2_data.c
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

/* Block parameters (default storage) */
P_code_gen_ac2_T code_gen_ac2_P = {
  /* Mask Parameter: DiscreteDerivative_ICPrevScaled
   * Referenced by: '<S1>/UD'
   */
  0.0,

  /* Computed Parameter: TSamp_WtEt
   * Referenced by: '<S1>/TSamp'
   */
  12.5,

  /* Expression: (-2*3.14)/(11*4)
   * Referenced by: '<Root>/Gain'
   */
  -0.14272727272727273,

  /* Expression: [0.1]
   * Referenced by: '<Root>/Discrete Filter'
   */
  0.1,

  /* Expression: [1 ,-0.9]
   * Referenced by: '<Root>/Discrete Filter'
   */
  { 1.0, -0.9 },

  /* Expression: 0
   * Referenced by: '<Root>/Discrete Filter'
   */
  0.0,

  /* Expression: 100
   * Referenced by: '<Root>/Constant'
   */
  100.0,

  /* Expression: 0
   * Referenced by: '<Root>/Unit Delay'
   */
  0.0,

  /* Expression: 0
   * Referenced by: '<Root>/Unit Delay1'
   */
  0.0,

  /* Expression: 255
   * Referenced by: '<Root>/Saturation'
   */
  255.0,

  /* Expression: -255
   * Referenced by: '<Root>/Saturation'
   */
  -255.0,

  /* Expression: 100
   * Referenced by: '<Root>/Constant1'
   */
  100.0,

  /* Expression: 0
   * Referenced by: '<Root>/Constant2'
   */
  0.0,

  /* Expression: 1
   * Referenced by: '<Root>/Constant3'
   */
  1.0,

  /* Expression: 0
   * Referenced by: '<Root>/N_prev'
   */
  0.0,

  /* Expression: 2*pi/(0.08*44)
   * Referenced by: '<Root>/Counts to rad_s'
   */
  1.7849958259032916
};

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
