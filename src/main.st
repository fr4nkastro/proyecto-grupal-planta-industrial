TYPE
  FSM1_TSTATUS : (FSM1_ESPERA, FSM1_ARRANCANDO_BANDAS, FSM1_ESPERANDO_CLASIFICACION, FSM1_ESPERANDO_DETECCION_PIEZA, FSM1_CLAMPEANDO);
  FSM1_TRANSITIONS : (FSM1_INICIAR, FSM1_DESHABILITADO, FSM1_CLASIFICAR_CAJAS_COLOR, FSM1_DETECTAR_PIEZA_EMPUJAR, FSM1_CLAMPEAR);
  FSM2_TSTATUS : (FSM2_NULLL, FSM2_VALIDANDO_TRANSACCION, FSM2_INICIANDO_SECUENCIA);
  FSM2_TTRANSITIONS : (FSM2_DESHABILITADO, FSM2_INICIAR_SECUENCIA, FSM2_DETECTAR_PALLET);
END_TYPE

FUNCTION_BLOCK FSM1_Petri
  VAR_EXTERNAL
    FSM1_CurrentTransition : FSM1_TRANSITIONS;
    FSM1_CurrentStatus : FSM1_TSTATUS;
  END_VAR

  (*Red FSM1_Petri*)
  IF FSM1_CurrentTransition = FSM1_INICIAR 
    THEN
      FSM1_CurrentStatus:=FSM1_ARRANCANDO_BANDAS;
  END_IF;

  IF FSM1_CurrentTransition = FSM1_CLASIFICAR_CAJAS_COLOR 
    THEN
      FSM1_CurrentStatus:=FSM1_ESPERANDO_CLASIFICACION;
  END_IF;

  IF FSM1_CurrentTransition = FSM1_DETECTAR_PIEZA_EMPUJAR
      THEN
        FSM1_CurrentStatus:=FSM1_ESPERANDO_DETECCION_PIEZA;
  END_IF;

  IF FSM1_CurrentTransition = FSM1_CLAMPEAR
      THEN
        FSM1_CurrentStatus:=FSM1_CLAMPEANDO;
  END_IF;

END_FUNCTION_BLOCK

FUNCTION_BLOCK FSM1_Triggers
  VAR_EXTERNAL
    FSM1_CurrentStatus : FSM1_TSTATUS;
    FSM1_CurrentTransition : FSM1_TRANSITIONS;
  END_VAR
  VAR
    FSM1_FTrigStop : F_TRIG;
  END_VAR
  VAR_EXTERNAL
    FSM1_RCSorting1 : BOOL;
    FSM1_RCSorting2 : BOOL;
    FSM1_RCSorting3 : BOOL;
    FSM1_RCSorting4 : BOOL;
    FSM1_RCSorting5 : BOOL;
    FSM1_RCSorting6 : BOOL;
    FSM1_RCSorting7 : BOOL;
    FSM1_RCSorting8 : BOOL;
    FSM1_RCSorting9 : BOOL;
    FSM1_BtnStop : BOOL;
    FSM1_BtnStart : BOOL;
    FSM1_SensorVision1 : INT;
  END_VAR
  VAR
    SensorVision1Value : INT;
  END_VAR
  VAR_EXTERNAL
    FSM1_SortingSensor1 : BOOL;
    FSM1_SortingSensor2 : BOOL;
    FSM1_PusherSorting1 : BOOL;
    FSM1_PusherSorting2 : BOOL;
  END_VAR
  VAR
    TP_Pusher1 : TP;
    TP_Pusher2 : TP;
  END_VAR
  VAR_EXTERNAL
    FSM1_RCGreen : BOOL;
    FSM1_RCBlue : BOOL;
  END_VAR
  VAR
    FTRIG_Pusher1 : F_TRIG;
    FTRIG_Pusher2 : F_TRIG;
  END_VAR

  FSM1_FTrigStop(

       CLK := FSM1_BtnStop
  );

  IF FSM1_FTrigStop.Q THEN
    FSM1_CurrentTransition:=FSM1_DESHABILITADO;
    FSM1_CurrentStatus:= FSM1_ESPERA;
    SensorVision1Value:=0;
    FSM1_RCSorting1:=FALSE;
    FSM1_RCSorting2:=FALSE;
    FSM1_RCSorting3:=FALSE;
    FSM1_RCSorting4:=FALSE;
    FSM1_RCSorting5:=FALSE;
    FSM1_RCSorting6:=FALSE;
    FSM1_RCSorting7:=FALSE;
    FSM1_RCSorting8:=FALSE;
    FSM1_RCSorting9:=FALSE;
    FSM1_RCGreen:=FALSE;
    FSM1_RCBlue:=FALSE;
  END_IF;

  IF FSM1_CurrentStatus = FSM1_ESPERA
    THEN
    IF FSM1_BtnStart
      THEN
        FSM1_CurrentTransition:= FSM1_INICIAR;
    END_IF;
  END_IF;

  IF FSM1_CurrentStatus = FSM1_ARRANCANDO_BANDAS
    THEN
        FSM1_RCSorting1:=TRUE;
        FSM1_RCSorting2:=TRUE;
        FSM1_RCSorting3:=TRUE;
        FSM1_RCSorting4:=TRUE;
        FSM1_RCSorting5:=TRUE;
        FSM1_RCSorting6:=TRUE;
        FSM1_RCSorting7:=TRUE;
        FSM1_RCSorting8:=TRUE;
        FSM1_RCSorting9:=TRUE;
        FSM1_RCGreen:=TRUE;
        FSM1_RCBlue:=TRUE;
        SensorVision1Value:=0;
        FSM1_CurrentTransition:=FSM1_CLASIFICAR_CAJAS_COLOR;
  END_IF;

  IF FSM1_CurrentStatus = FSM1_ESPERANDO_CLASIFICACION 
    THEN
      IF FSM1_SensorVision1 > 0 THEN
        SensorVision1Value:= FSM1_SensorVision1;    
        FSM1_CurrentTransition := FSM1_DETECTAR_PIEZA_EMPUJAR;
      END_IF;
  END_IF;

  IF FSM1_CurrentStatus =FSM1_ESPERANDO_DETECCION_PIEZA 
      THEN
        IF  SensorVision1Value = 5 OR 
            SensorVision1Value = 6
        THEN
          TP_Pusher1(
           IN := FSM1_SortingSensor1,
           PT := T#2s,
           Q => FSM1_PusherSorting1
          );
          FTRIG_Pusher1(
              CLK := TP_Pusher1.Q
            );
          IF FTRIG_Pusher1.Q 

            THEN

             FSM1_CurrentTransition := FSM1_CLAMPEAR;

          END_IF;
        END_IF;
        
        IF  SensorVision1Value = 2 OR 
            SensorVision1Value = 3
          THEN
            TP_Pusher2(
             IN := FSM1_SortingSensor2,
             PT := T#2s,
             Q => FSM1_PusherSorting2
            );
            FTRIG_Pusher2(
              CLK:= TP_Pusher2.Q
            );
            IF FTRIG_Pusher2.Q 
              THEN
              FSM1_CurrentTransition := FSM1_CLAMPEAR;
            END_IF;
        END_IF;
        
  END_IF;
        
        
            
              
END_FUNCTION_BLOCK

PROGRAM main
  VAR
    FSM1_Petri0 : FSM1_Petri;
    FSM1_Triggers0 : FSM1_Triggers;
  END_VAR

  FSM1_Petri0();
  FSM1_Triggers0();
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      FSM1_CurrentStatus : FSM1_TSTATUS := FSM1_ESPERA;
      FSM1_CurrentTransition : FSM1_TRANSITIONS := FSM1_DESHABILITADO;
      FSM2_CurrentTransition : FSM2_TTRANSITIONS := FSM2_DESHABILITADO;
      FSM2_CurrentStatus : FSM2_TSTATUS := FSM2_VALIDANDO_TRANSACCION;
      FSM1_BtnStart AT %IX100.0 : BOOL := FALSE;
      FSM1_BtnStop AT %IX100.1 : BOOL := TRUE;
      FSM1_SortingSensor1 AT %IX100.2 : BOOL := TRUE;
      FSM1_SortingSensor2 AT %IX100.3 : BOOL := TRUE;
      FSM1_RCSorting1 AT %QX100.0 : BOOL := FALSE;
      FSM1_RCSorting2 AT %QX100.1 : BOOL := FALSE;
      FSM1_RCSorting3 AT %QX100.2 : BOOL := FALSE;
      FSM1_RCSorting4 AT %QX100.3 : BOOL := FALSE;
      FSM1_RCSorting5 AT %QX100.4 : BOOL := FALSE;
      FSM1_RCSorting6 AT %QX100.5 : BOOL := FALSE;
      FSM1_RCSorting7 AT %QX100.6 : BOOL := FALSE;
      FSM1_RCSorting8 AT %QX100.7 : BOOL := FALSE;
      FSM1_RCSorting9 AT %QX101.0 : BOOL := FALSE;
      FSM1_PusherSorting1 AT %QX101.1 : BOOL := FALSE;
      FSM1_PusherSorting2 AT %QX101.2 : BOOL := FALSE;
      FSM1_RcGreen AT %QX101.3 : BOOL := FALSE;
      FSM1_RcBlue AT %QX101.4 : BOOL := FALSE;
      FSM1_SensorVision1 AT %IW100 : INT := 0;
    END_VAR
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : main;
  END_RESOURCE
END_CONFIGURATION

(*DBG:char md5[] = "9363ddaa148e2e82ec1b85a8e13fcac9";*)
(*DBG:/**)
(*DBG: * This file is part of OpenPLC Runtime*)
(*DBG: **)
(*DBG: * Copyright (C) 2023 Autonomy, GP Orcullo*)
(*DBG: * Based on the work by GP Orcullo on Beremiz for uC*)
(*DBG: **)
(*DBG: * This program is free software; you can redistribute it and/or*)
(*DBG: * modify it under the terms of the GNU General Public License*)
(*DBG: * as published by the Free Software Foundation; either version 2*)
(*DBG: * of the License, or (at your option) any later version.*)
(*DBG: **)
(*DBG: * This program is distributed in the hope that it will be useful,*)
(*DBG: * but WITHOUT ANY WARRANTY; without even the implied warranty of*)
(*DBG: * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the*)
(*DBG: * GNU General Public License for more details.*)
(*DBG: **)
(*DBG: * You should have received a copy of the GNU General Public License*)
(*DBG: * along with this program; If not, see <http://www.gnu.org/licenses/>.*)
(*DBG: **)
(*DBG: */*)
(*DBG:*)
(*DBG:#include <stdbool.h>*)
(*DBG:*)
(*DBG:#include "iec_types_all.h"*)
(*DBG:#include "POUS.h"*)
(*DBG:*)
(*DBG:#define SAME_ENDIANNESS      0*)
(*DBG:#define REVERSE_ENDIANNESS   1*)
(*DBG:*)
(*DBG:uint8_t endianness;*)
(*DBG:*)
(*DBG:*)
(*DBG:extern __IEC_FSM1_TSTATUS_t RES0__FSM1_CURRENTSTATUS;*)
(*DBG:extern __IEC_FSM1_TRANSITIONS_t RES0__FSM1_CURRENTTRANSITION;*)
(*DBG:extern __IEC_FSM2_TTRANSITIONS_t RES0__FSM2_CURRENTTRANSITION;*)
(*DBG:extern __IEC_FSM2_TSTATUS_t RES0__FSM2_CURRENTSTATUS;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_BTNSTART;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_BTNSTOP;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_SORTINGSENSOR1;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_SORTINGSENSOR2;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING1;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING2;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING3;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING4;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING5;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING6;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING7;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING8;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCSORTING9;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_PUSHERSORTING1;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_PUSHERSORTING2;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCGREEN;*)
(*DBG:extern __IEC_BOOL_t RES0__FSM1_RCBLUE;*)
(*DBG:extern __IEC_INT_t RES0__FSM1_SENSORVISION1;*)
(*DBG:extern MAIN RES0__INSTANCE0;*)
(*DBG:*)
(*DBG:static const struct {*)
(*DBG:    void *ptr;*)
(*DBG:    __IEC_types_enum type;*)
(*DBG:} debug_vars[] = {*)
(*DBG:    {&(RES0__FSM1_BTNSTART), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_BTNSTOP), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_SORTINGSENSOR1), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_SORTINGSENSOR2), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING1), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING2), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING3), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING4), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING5), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING6), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING7), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING8), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCSORTING9), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_PUSHERSORTING1), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_PUSHERSORTING2), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCGREEN), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_RCBLUE), BOOL_ENUM},*)
(*DBG:    {&(RES0__FSM1_SENSORVISION1), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_PETRI0.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_PETRI0.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_FTRIGSTOP.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_FTRIGSTOP.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_FTRIGSTOP.CLK), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_FTRIGSTOP.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_FTRIGSTOP.M), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING1), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING2), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING3), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING4), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING5), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING6), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING7), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING8), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCSORTING9), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_BTNSTOP), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_BTNSTART), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_SENSORVISION1), INT_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.SENSORVISION1VALUE), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_SORTINGSENSOR1), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_SORTINGSENSOR2), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_PUSHERSORTING1), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_PUSHERSORTING2), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.IN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.PT), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.ET), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.STATE), SINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER1.START_TIME), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.IN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.PT), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.ET), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.STATE), SINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.TP_PUSHER2.START_TIME), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCGREEN), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FSM1_RCBLUE), BOOL_P_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER1.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER1.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER1.CLK), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER1.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER1.M), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER2.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER2.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER2.CLK), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER2.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FSM1_TRIGGERS0.FTRIG_PUSHER2.M), BOOL_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               76*)
(*DBG:*)
(*DBG:uint16_t get_var_count(void)*)
(*DBG:{*)
(*DBG:    return VAR_COUNT;*)
(*DBG:}*)
(*DBG:*)
(*DBG:size_t get_var_size(size_t idx)*)
(*DBG:{*)
(*DBG:    if (idx >= VAR_COUNT)*)
(*DBG:    {*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:    case BOOL_P_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return sizeof(TIME);*)
(*DBG:    case INT_ENUM:*)
(*DBG:    case INT_P_ENUM:*)
(*DBG:        return sizeof(INT);*)
(*DBG:    case SINT_ENUM:*)
(*DBG:        return sizeof(SINT);*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void *get_var_addr(size_t idx)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    case BOOL_P_ENUM:*)
(*DBG:        return (void *)((((__IEC_BOOL_p *) ptr)->flags & __IEC_FORCE_FLAG) *)
(*DBG:                        ? &(((__IEC_BOOL_p *) ptr)->fvalue) *)
(*DBG:                        : ((__IEC_BOOL_p *) ptr)->value);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return (void *)&((__IEC_TIME_t *) ptr)->value;*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return (void *)&((__IEC_INT_t *) ptr)->value;*)
(*DBG:    case INT_P_ENUM:*)
(*DBG:        return (void *)((((__IEC_INT_p *) ptr)->flags & __IEC_FORCE_FLAG) *)
(*DBG:                        ? &(((__IEC_INT_p *) ptr)->fvalue) *)
(*DBG:                        : ((__IEC_INT_p *) ptr)->value);*)
(*DBG:    case SINT_ENUM:*)
(*DBG:        return (void *)&((__IEC_SINT_t *) ptr)->value;*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void force_var(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    if (forced) {*)
(*DBG:        size_t var_size = get_var_size(idx);*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case BOOL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_BOOL_t *) ptr)->value = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case BOOL_P_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_p *) ptr)->fvalue, val, var_size);*)
(*DBG:            //((__IEC_BOOL_p *) ptr)->fvalue = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_p *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case TIME_ENUM: {*)
(*DBG:            memcpy(&((__IEC_TIME_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_TIME_t *) ptr)->value = *((TIME *) val);*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case INT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_INT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_INT_t *) ptr)->value = *((INT *) val);*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case INT_P_ENUM: {*)
(*DBG:            memcpy(&((__IEC_INT_p *) ptr)->fvalue, val, var_size);*)
(*DBG:            //((__IEC_INT_p *) ptr)->fvalue = *((INT *) val);*)
(*DBG:            ((__IEC_INT_p *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case SINT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_SINT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_SINT_t *) ptr)->value = *((SINT *) val);*)
(*DBG:            ((__IEC_SINT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_P_ENUM:*)
(*DBG:            ((__IEC_BOOL_p *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case TIME_ENUM:*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_ENUM:*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_P_ENUM:*)
(*DBG:            ((__IEC_INT_p *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case SINT_ENUM:*)
(*DBG:            ((__IEC_SINT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void swap_bytes(void *ptr, size_t size) *)
(*DBG:{*)
(*DBG:    uint8_t *bytePtr = (uint8_t *)ptr;*)
(*DBG:    size_t i;*)
(*DBG:    for (i = 0; i < size / 2; ++i) *)
(*DBG:    {*)
(*DBG:        uint8_t temp = bytePtr[i];*)
(*DBG:        bytePtr[i] = bytePtr[size - 1 - i];*)
(*DBG:        bytePtr[size - 1 - i] = temp;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void trace_reset(void)*)
(*DBG:{*)
(*DBG:    for (size_t i=0; i < VAR_COUNT; i++) *)
(*DBG:    {*)
(*DBG:        force_var(i, false, 0);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_trace(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    if (idx >= 0 && idx < VAR_COUNT) *)
(*DBG:    {*)
(*DBG:        if (endianness == REVERSE_ENDIANNESS)*)
(*DBG:        {*)
(*DBG:            // Aaaaarghhhh... Stupid AVR is Big Endian.*)
(*DBG:            swap_bytes(val, get_var_size(idx));*)
(*DBG:        }*)
(*DBG:*)
(*DBG:        force_var(idx, forced, val);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_endianness(uint8_t value)*)
(*DBG:{*)
(*DBG:    if (value == SAME_ENDIANNESS || value == REVERSE_ENDIANNESS)*)
(*DBG:    {*)
(*DBG:        endianness = value;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)