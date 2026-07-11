/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * File: code_gen_ac2_types.h
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

#ifndef code_gen_ac2_types_h_
#define code_gen_ac2_types_h_
#include "rtwtypes.h"
#include "MW_SVD.h"
#ifndef struct_tag_um27AmhtbslH2i5VSgy0RG
#define struct_tag_um27AmhtbslH2i5VSgy0RG

struct tag_um27AmhtbslH2i5VSgy0RG
{
  int32_T __dummy;
};

#endif                                 /* struct_tag_um27AmhtbslH2i5VSgy0RG */

#ifndef typedef_b_arduinodriver_ArduinoDigita_T
#define typedef_b_arduinodriver_ArduinoDigita_T

typedef struct tag_um27AmhtbslH2i5VSgy0RG b_arduinodriver_ArduinoDigita_T;

#endif                             /* typedef_b_arduinodriver_ArduinoDigita_T */

#ifndef struct_tag_lLXm9RMdC1wJGOFiPwVXeD
#define struct_tag_lLXm9RMdC1wJGOFiPwVXeD

struct tag_lLXm9RMdC1wJGOFiPwVXeD
{
  boolean_T matlabCodegenIsDeleted;
  int32_T isInitialized;
  boolean_T isSetupComplete;
  b_arduinodriver_ArduinoDigita_T DigitalIODriverObj;
};

#endif                                 /* struct_tag_lLXm9RMdC1wJGOFiPwVXeD */

#ifndef typedef_codertarget_arduinobase_block_T
#define typedef_codertarget_arduinobase_block_T

typedef struct tag_lLXm9RMdC1wJGOFiPwVXeD codertarget_arduinobase_block_T;

#endif                             /* typedef_codertarget_arduinobase_block_T */

#ifndef struct_tag_FHZ7JioS7qem7UEAKh2LfE
#define struct_tag_FHZ7JioS7qem7UEAKh2LfE

struct tag_FHZ7JioS7qem7UEAKh2LfE
{
  boolean_T matlabCodegenIsDeleted;
  int32_T isInitialized;
  boolean_T isSetupComplete;
  boolean_T TunablePropsChanged;
  uint8_T Index;
};

#endif                                 /* struct_tag_FHZ7JioS7qem7UEAKh2LfE */

#ifndef typedef_codertarget_arduinobase_inter_T
#define typedef_codertarget_arduinobase_inter_T

typedef struct tag_FHZ7JioS7qem7UEAKh2LfE codertarget_arduinobase_inter_T;

#endif                             /* typedef_codertarget_arduinobase_inter_T */

#ifndef struct_tag_7VFuPw0vSNrn5pRgG8Mc4C
#define struct_tag_7VFuPw0vSNrn5pRgG8Mc4C

struct tag_7VFuPw0vSNrn5pRgG8Mc4C
{
  MW_Handle_Type MW_PWM_HANDLE;
};

#endif                                 /* struct_tag_7VFuPw0vSNrn5pRgG8Mc4C */

#ifndef typedef_e_matlabshared_ioclient_perip_T
#define typedef_e_matlabshared_ioclient_perip_T

typedef struct tag_7VFuPw0vSNrn5pRgG8Mc4C e_matlabshared_ioclient_perip_T;

#endif                             /* typedef_e_matlabshared_ioclient_perip_T */

#ifndef struct_tag_RWocY1aAVmuibq0rYX5t0G
#define struct_tag_RWocY1aAVmuibq0rYX5t0G

struct tag_RWocY1aAVmuibq0rYX5t0G
{
  boolean_T matlabCodegenIsDeleted;
  int32_T isInitialized;
  boolean_T isSetupComplete;
  e_matlabshared_ioclient_perip_T PWMDriverObj;
};

#endif                                 /* struct_tag_RWocY1aAVmuibq0rYX5t0G */

#ifndef typedef_codertarget_arduinobase_int_m_T
#define typedef_codertarget_arduinobase_int_m_T

typedef struct tag_RWocY1aAVmuibq0rYX5t0G codertarget_arduinobase_int_m_T;

#endif                             /* typedef_codertarget_arduinobase_int_m_T */

/* Parameters (default storage) */
typedef struct P_code_gen_ac2_T_ P_code_gen_ac2_T;

/* Forward declaration for rtModel */
typedef struct tag_RTM_code_gen_ac2_T RT_MODEL_code_gen_ac2_T;

#endif                                 /* code_gen_ac2_types_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
