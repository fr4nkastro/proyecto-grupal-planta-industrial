TYPE
  FSM1_TSTATUS : (STANDBY, WAITING_BOX, COUNTED2BOXES, FIRST_PUSH, COUNTED2PUSHES, ADDING_PALLET_LEVEL, CLAMPED, PALLET_AT_ENTRY, PALLET_LOADED, ELEVATOR_UP, ELEVATOR_DOWN, EMPTY_EXIT_CONVEYOR);
  FSM1_TRANSITIONS : (START, COUNT2BOXES, COUNT_PUSH, COUNT_PUSH2, PALLET_LEVEL, ADD_PALLET_LEVEL, CLAMP, DETECT_PALLET_AT_ENTRY, DETECT_ELEVATOR_UP, DETECT_ELEVATOR_DOWN, DETECT_EMPTY_CONVEYOR, DISABLE);
  FSM2_TSTATUS : (FSM2_STANDBY, FSM2_NULLL);
  FSM2_TTRANSITIONS : (FSM2_DEACTIVATED);
END_TYPE

FUNCTION_BLOCK FSM1_Petri
  VAR_EXTERNAL
    CurrentTransition : FSM1_TRANSITIONS;
    CurrentStatus : FSM1_TSTATUS;
  END_VAR

  (*Red FSM1_Petri*)
  IF CurrentTransition = START 
    THEN
      CurrentStatus:=WAITING_BOX;
  END_IF;

  (*Count2Boxes*)
  IF CurrentTransition = COUNT2BOXES
      THEN
        CurrentStatus:= COUNTED2BOXES;
  END_IF;

  (*FirstPush*)
  IF CurrentTransition = COUNT_PUSH
    THEN
      CurrentStatus:=WAITING_BOX;
  END_IF;

  IF CurrentTransition = COUNT_PUSH2
      THEN
        CurrentStatus:= COUNTED2PUSHES;
  END_IF;

  IF CurrentTransition = PALLET_LEVEL 
    THEN
      CurrentStatus:= ADDING_PALLET_LEVEL;
  END_IF;

  IF CurrentTransition = ADD_PALLET_LEVEL THEN
    CurrentStatus:=WAITING_BOX;
  END_IF;

  IF CurrentTransition = CLAMP
    THEN
      CurrentStatus:= CLAMPED;
  END_IF;


  IF CurrentTransition = DETECT_PALLET_AT_ENTRY
    THEN
      CurrentStatus:= PALLET_AT_ENTRY;
  END_IF;

  IF CurrentTransition = DETECT_ELEVATOR_UP
    THEN
      CurrentStatus:= ELEVATOR_UP;
  END_IF;

  IF CurrentTransition = DETECT_ELEVATOR_DOWN
    THEN
      CurrentStatus:= ELEVATOR_DOWN;
  END_IF;

  IF CurrentTransition = DETECT_EMPTY_CONVEYOR
    THEN
      CurrentStatus:= EMPTY_EXIT_CONVEYOR;
  END_IF;

END_FUNCTION_BLOCK

FUNCTION_BLOCK FSM1_Triggers
  VAR_EXTERNAL
    CurrentStatus : FSM1_TSTATUS;
    CurrentTransition : FSM1_TRANSITIONS;
    BoxFeeder : BOOL;
  END_VAR
  VAR
    CTUBox : CTU;
    CTUPush : CTU;
  END_VAR
  VAR_EXTERNAL
    SensorBoxAtEntry : BOOL;
    PushOut : BOOL;
  END_VAR
  VAR
    TONPush : TON;
    FTrigBox : F_TRIG;
    TONWaitPush : TON;
    TPRetract : TP;
    TONWaitLastBox : TON;
  END_VAR
  VAR_EXTERNAL
    ButtonStart : BOOL;
    CounterBoxes : INT;
    CounterPushes : INT;
  END_VAR
  VAR
    FTrigPush : F_TRIG;
    FTrigRetract : F_TRIG;
  END_VAR
  VAR_EXTERNAL
    ClampOut : BOOL;
    PalletFeederOut : BOOL;
    LoadBeltOut : BOOL;
    LoadPalletOut : BOOL;
    SensorPalletAtEntry : BOOL;
  END_VAR
  VAR
    RTrigPalletAtEntry : R_TRIG;
  END_VAR
  VAR_EXTERNAL
    MoveToLimitOut : BOOL;
    ElevatorUpOut : BOOL;
    SensorElevatorMoving : BOOL;
  END_VAR
  VAR
    FTrigElevatorMoving : F_TRIG;
    FTrigPalletLoaded : R_TRIG;
    TPPalletDetected : TP;
  END_VAR
  VAR_EXTERNAL
    OpenPlateOut : BOOL;
    ElevatorDownOut : BOOL;
    ExitConveyorOut : BOOL;
  END_VAR
  VAR
    TONEmptyExitConveyor : TON;
    TONElevatorDown : TON;
  END_VAR
  VAR_EXTERNAL
    TurnOut : BOOL;
    StartLightOut : BOOL;
    StopLightOut : BOOL;
    WarningLightOut : BOOL;
    ResetLightOut : BOOL;
    ButtonReset : BOOL;
    ButtonStop : BOOL;
  END_VAR
  VAR
    FTrigStop : F_TRIG;
  END_VAR
  VAR_EXTERNAL
    SensorPalletLoaded : BOOL;
  END_VAR
  VAR
    MaxBoxes : INT;
    MaxPushes : INT;
    MaxLevels : INT := 1;
  END_VAR
  VAR_EXTERNAL
    CounterLevels : INT;
  END_VAR
  VAR
    CTULevels : CTU;
    TONAddLevel : TON;
    TONAddLevel0 : TON;
    TONAddLevel1 : TON;
  END_VAR

  FTrigStop(

       CLK := ButtonStop
  );

  IF FTrigStop.Q THEN
    CurrentTransition:=DISABLE;
    CurrentStatus:= STANDBY;
    StartLightOut:= FALSE;
    ClampOut:=FALSE;
    WarningLightOut:= TRUE;
    StopLightOut:= TRUE;
    ExitConveyorOut:=FALSE;
    LoadBeltOut:=FALSE;
    BoxFeeder:=FALSE;
    PalletFeederOut:=FALSE;
    ElevatorUpOut:=FALSE;
    ElevatorDownOut:=FALSE;
    LoadPalletOut:=FALSE;
    
  END_IF;

  IF CurrentStatus = STANDBY
    THEN
    StopLightOut:= TRUE;
    IF ButtonReset THEN
      ResetLightOut:=TRUE;

      CTUBox(

        R:= TRUE
        );
        CounterBoxes:=0;

      CTUPush(

        R:=TRUE
        );
        CounterPushes:=0;
    ELSE
      ResetLightOut:=FALSE;

    END_IF;
    IF ButtonStart 
      THEN
        StartLightOut:= TRUE;
        StopLightOut:= FALSE;
        WarningLightOut:= False;
        CurrentTransition:= START;
    END_IF;
  END_IF;

  IF CurrentStatus = WAITING_BOX
    THEN
      IF TurnOut = TRUE THEN
        MaxBoxes:=3;
        MaxPushes:=2;
      ELSE 
        MaxBoxes:=2;
        MaxPushes:=3;
      END_IF;
      (*
      Bloque F_TRIG (detector de flanco descendente) detecta cuando se activa la entrada del sensor que detecta cajas
      Para que el CTUBox (counter) incrementa el counter
      *)
      FTrigBox(
        CLK := SensorBoxAtEntry
      );
      CTUBox(
        R:= FALSE,
        CU := FTrigBox.Q,
        PV := MaxBoxes,
        CV => CounterBoxes
       );
      TONWaitLastBox(
       IN := CTUBox.Q,
       PT := T#500ms
      );
      (*Delay paso ultima caja*)
      IF TONWaitLastBox.Q
        THEN
        BoxFeeder := FALSE;
        LoadBeltOut:=TRUE;
      ELSE
        BoxFeeder:=TRUE;
        LoadBeltOut:=TRUE;
      END_IF;
      (*Delay antes de espera de cajas en posición de empuje*)
      TONWaitPush(
       IN := TONWaitLastBox.Q,
       PT := T#1500ms
      );
      IF TONWaitPush.Q
        THEN
          (* Habilitar PushOut al inicio *)
          TONWaitLastBox(
          IN := FALSE
          );
          PushOut := TRUE;
          CurrentTransition:=COUNT2BOXES;
      END_IF;
  END_IF;

  IF CurrentStatus = COUNTED2BOXES 
    THEN
      BoxFeeder := FALSE;
      LoadBeltOut := FALSE;
      (* Iniciar temporizador para mantener PushOut activo por 2 segundos *)
      TONPush(
        IN := PushOut,
        PT := T#1s
      );

      (* Cuando el temporizador se cumple, desactiva PushOut *)
      IF TONPush.Q THEN
          PushOut := FALSE;
      END_IF;

      (* Detectar flanco descendente de PushOut para contabilizar *)
      FTrigPush(
        CLK := PushOut  (* Detecta cuando PushOut pasa de TRUE a FALSE *)
      );

      (* Contar solo cuando PushOut realmente ha vuelto a FALSE y ha pasado el tiempo de retracción *)
      CTUPush(
        R := FALSE,
        CU := FTrigPush.Q,  (* Incrementa solo en el flanco ascendente del temporizador *)
        PV := MaxPushes,
        CV => CounterPushes
      );

      (* Cambiar de estado solo si el actuador se ha retraído y contado correctamente *)
      IF CTUPush.CV < MaxPushes AND FTrigPush.Q THEN
        CTUBox(
          R:= TRUE
        );
        TONPush(
        IN:= FALSE);
        CurrentTransition := COUNT_PUSH;
      END_IF;
      IF CTUPush.CV = MaxPushes AND FTrigPush.Q THEN
        CTUBox(
          R:= TRUE
        );
        CTUPush(
          R:= TRUE
        );
        TONPush(
        IN:= FALSE);
        IF TurnOut = FALSE THEN
            TurnOut := TRUE;
        ELSE
          TurnOut := FALSE;
        END_IF;
        CurrentTransition := COUNT_PUSH2;
      END_IF;
  END_IF;

  IF CurrentStatus = COUNTED2PUSHES 
    THEN
      CounterLevels:=CounterLevels+1;
      IF CounterLevels =1 OR  CounterLevels >= MaxLevels THEN
        ClampOut:= TRUE;
        PalletFeederOut:= TRUE;
        LoadPalletOut:=TRUE;
        CurrentTransition:=CLAMP;
      ELSE 
        CurrentTransition:=PALLET_LEVEL;
      END_IF;
  END_IF;

  IF CurrentStatus = ADDING_PALLET_LEVEL
    THEN
    IF CounterLevels < MaxLevels THEN

          OpenPlateOut:=TRUE;
          MoveToLimitOut:=FALSE;
          ElevatorUpOut:=FALSE;
          TONAddLevel(
            IN:= NOT MoveToLimitOut,
            PT:=T#3s
          );
          IF TONAddLevel.Q THEN  
            ElevatorDownOut:=TRUE;
            TONAddLevel1(
              IN:=TONAddLevel.Q,
              PT:=T#3s
            );
            IF TONAddLevel1.Q THEN
              ClampOut:=FALSE;
              OpenPlateOut:=FALSE;
              TONAddLevel1(
                IN:=FALSE
                );
              TONAddLevel(
                IN:=FALSE
              );
              CurrentTransition:= ADD_PALLET_LEVEL;
            END_IF;
          END_IF;
      END_IF;
  END_IF;

  IF CurrentStatus = CLAMPED THEN
          (*Temporizador para detección de palet*)
          (*Detector de flanco 1,0*)
          FTrigPalletLoaded(
            CLK:=SensorPalletLoaded
            ); 
          IF FTrigPalletLoaded.Q THEN (* Ha pasado 1 segundo desde la detección *)
              PalletFeederOut := FALSE;
              LoadPalletOut := FALSE;
              CurrentTransition := DETECT_PALLET_AT_ENTRY;
              
          END_IF;
  END_IF;


  IF CurrentStatus = PALLET_AT_ENTRY
    THEN
      MoveToLimitOut:= TRUE;
      ElevatorUpOut:= TRUE;
      (*Detectar flanco descendente SensorElevatorMoving 1,0*)
      FTrigElevatorMoving(
        CLK:=SensorElevatorMoving
      );
      IF FTrigElevatorMoving.Q
        THEN
          OpenPlateOut:=TRUE;
          CurrentTransition:= DETECT_ELEVATOR_UP;
      END_IF;
      
  END_IF;

  IF CurrentStatus = ELEVATOR_UP
    THEN
      ElevatorUpOut:=FALSE;
      TONElevatorDown(
        IN:=OpenPlateOut,
        PT:=T#3s
      );
      IF TONElevatorDown.Q
        THEN
        TONElevatorDown(
          IN:=FALSE
        );
        IF CounterLevels < MaxLevels THEN
          MoveToLimitOut:=FALSE;
          ElevatorDownOut:=TRUE;
          TONAddLevel1(
            IN:= NOT MoveToLimitOut,
            PT:=T#3s
          );
          IF TONAddLevel1.Q THEN  
            ClampOut:=FALSE;
            OpenPlateOut:=FALSE;
            ElevatorDownOut:=FALSE;
            CurrentTransition:= ADD_PALLET_LEVEL;
          END_IF;
        ELSE
          ElevatorDownOut:=TRUE;
          CurrentTransition:=DETECT_ELEVATOR_DOWN;
        END_IF;
      END_IF;
  END_IF;



  IF CurrentStatus = ELEVATOR_DOWN
    THEN
       
      (*Detectar flanco descendente SensorElevatorMoving 1,0*)
      FTrigElevatorMoving(
        CLK:=SensorElevatorMoving
      );
      IF FTrigElevatorMoving.Q
        THEN
          ElevatorDownOut:=FALSE;
          ClampOut:=FALSE;
          OpenPlateOut:=FALSE;
          LoadPalletOut:=TRUE;
          ExitConveyorOut:=TRUE;
          CurrentTransition:= DETECT_EMPTY_CONVEYOR;
      END_IF;
  END_IF;

  IF CurrentStatus = EMPTY_EXIT_CONVEYOR
    THEN
      TONEmptyExitConveyor(
        IN:= TRUE,
        PT:=T#10s
      );
      IF TONEmptyExitConveyor.Q
        THEN
          LoadPalletOut:=FALSE;
          ExitConveyorOut:=FALSE;
          TONEmptyExitConveyor(
            IN:=FALSE
          );
          CurrentTransition:=START;
      END_IF;
  END_IF;
END_FUNCTION_BLOCK

FUNCTION_BLOCK FSM2_Petri
  VAR_EXTERNAL
    FSM2_CurrentTransition : FSM2_TTRANSITIONS;
  END_VAR

  FSM2_CurrentTransition:=FSM2_DEACTIVATED;
END_FUNCTION_BLOCK

PROGRAM main
  VAR
    petri0 : FSM1_Petri;
    trigger0 : FSM1_Triggers;
    FSM2_Petri0 : FSM2_Petri;
  END_VAR

  petri0();
  trigger0();
  FSM2_Petri0();
END_PROGRAM


CONFIGURATION Config0

  RESOURCE FSM1_Res ON PLC
    VAR_GLOBAL
      CurrentStatus : FSM1_TSTATUS := STANDBY;
      CurrentTransition : FSM1_TRANSITIONS := DISABLE;
      FSM2_CurrentTransition : FSM2_TTRANSITIONS := FSM2_DEACTIVATED;
      PalletFeederOut AT %QX100.0 : BOOL := FALSE;
      LoadPalletOut AT %QX100.1 : BOOL := FALSE;
      ExitConveyorOut AT %QX100.2 : BOOL := FALSE;
      TurnOut AT %QX100.7 : BOOL := FALSE;
      PushOut AT %QX101.0 : BOOL := FALSE;
      LoadBeltOut AT %QX101.1 : BOOL := FALSE;
      ClampOut AT %QX101.2 : BOOL := FALSE;
      OpenPlateOut AT %QX101.3 : BOOL := FALSE;
      MoveToLimitOut AT %QX100.3 : BOOL := FALSE;
      ElevatorUpOut AT %QX100.4 : BOOL := FALSE;
      ElevatorDownOut AT %QX100.5 : BOOL := FALSE;
      BoxFeeder AT %QX100.6 : BOOL := FALSE;
      StartLightOut AT %QX101.5 : BOOL := FALSE;
      WarningLightOut AT %QX101.4 : BOOL := FALSE;
      ResetLightOut AT %QX101.6 : BOOL := FALSE;
      StopLightOut AT %QX101.7 : BOOL := FALSE;
      SensorPalletAtEntry AT %IX100.0 : BOOL := TRUE;
      SensorPalletLoaded AT %IX100.2 : BOOL := FALSE;
      ButtonStart AT %IX101.0 : BOOL := FALSE;
      ButtonReset AT %IX101.1 : BOOL := FALSE;
      ButtonStop AT %IX101.2 : BOOL := TRUE;
      SensorBoxAtEntry AT %IX100.3 : BOOL := TRUE;
      SensorElevatorMoving AT %IX100.7 : BOOL := FALSE;
      CounterBoxes AT %QW100 : INT := 0;
      CounterPushes AT %QW101 : INT := 0;
      CounterLevels AT %QW102 : INT := 0;
    END_VAR
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : main;
  END_RESOURCE
END_CONFIGURATION

(*DBG:char md5[] = "1806fc328e0f14065307204c7b704f8d";*)
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
(*DBG:extern __IEC_FSM1_TSTATUS_t FSM1_RES__CURRENTSTATUS;*)
(*DBG:extern __IEC_FSM1_TRANSITIONS_t FSM1_RES__CURRENTTRANSITION;*)
(*DBG:extern __IEC_FSM2_TTRANSITIONS_t FSM1_RES__FSM2_CURRENTTRANSITION;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__PALLETFEEDEROUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__LOADPALLETOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__EXITCONVEYOROUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__TURNOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__PUSHOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__LOADBELTOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__CLAMPOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__OPENPLATEOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__MOVETOLIMITOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__ELEVATORUPOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__ELEVATORDOWNOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__BOXFEEDER;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__STARTLIGHTOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__WARNINGLIGHTOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__RESETLIGHTOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__STOPLIGHTOUT;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__SENSORPALLETATENTRY;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__SENSORPALLETLOADED;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__BUTTONSTART;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__BUTTONRESET;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__BUTTONSTOP;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__SENSORBOXATENTRY;*)
(*DBG:extern __IEC_BOOL_t FSM1_RES__SENSORELEVATORMOVING;*)
(*DBG:extern __IEC_INT_t FSM1_RES__COUNTERBOXES;*)
(*DBG:extern __IEC_INT_t FSM1_RES__COUNTERPUSHES;*)
(*DBG:extern __IEC_INT_t FSM1_RES__COUNTERLEVELS;*)
(*DBG:extern MAIN FSM1_RES__INSTANCE0;*)
(*DBG:*)
(*DBG:static const struct {*)
(*DBG:    void *ptr;*)
(*DBG:    __IEC_types_enum type;*)
(*DBG:} debug_vars[] = {*)
(*DBG:    {&(FSM1_RES__PALLETFEEDEROUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__LOADPALLETOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__EXITCONVEYOROUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__TURNOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__PUSHOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__LOADBELTOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__CLAMPOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__OPENPLATEOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__MOVETOLIMITOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__ELEVATORUPOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__ELEVATORDOWNOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__BOXFEEDER), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__STARTLIGHTOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__WARNINGLIGHTOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__RESETLIGHTOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__STOPLIGHTOUT), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__SENSORPALLETATENTRY), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__SENSORPALLETLOADED), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__BUTTONSTART), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__BUTTONRESET), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__BUTTONSTOP), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__SENSORBOXATENTRY), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__SENSORELEVATORMOVING), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__COUNTERBOXES), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__COUNTERPUSHES), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__COUNTERLEVELS), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.PETRI0.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.PETRI0.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.BOXFEEDER), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.R), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.PV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU_T.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU_T.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU_T.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU_T.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUBOX.CU_T.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.R), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.PV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU_T.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU_T.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU_T.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU_T.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTUPUSH.CU_T.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.SENSORBOXATENTRY), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.PUSHOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONPUSH.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGBOX.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGBOX.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGBOX.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGBOX.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGBOX.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITPUSH.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPRETRACT.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONWAITLASTBOX.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.BUTTONSTART), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.COUNTERBOXES), INT_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.COUNTERPUSHES), INT_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPUSH.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPUSH.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPUSH.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPUSH.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPUSH.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGRETRACT.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGRETRACT.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGRETRACT.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGRETRACT.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGRETRACT.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CLAMPOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.PALLETFEEDEROUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.LOADBELTOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.LOADPALLETOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.SENSORPALLETATENTRY), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RTRIGPALLETATENTRY.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RTRIGPALLETATENTRY.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RTRIGPALLETATENTRY.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RTRIGPALLETATENTRY.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RTRIGPALLETATENTRY.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.MOVETOLIMITOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.ELEVATORUPOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.SENSORELEVATORMOVING), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGELEVATORMOVING.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGELEVATORMOVING.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGELEVATORMOVING.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGELEVATORMOVING.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGELEVATORMOVING.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPALLETLOADED.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPALLETLOADED.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPALLETLOADED.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPALLETLOADED.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGPALLETLOADED.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TPPALLETDETECTED.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.OPENPLATEOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.ELEVATORDOWNOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.EXITCONVEYOROUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONEMPTYEXITCONVEYOR.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONELEVATORDOWN.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TURNOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.STARTLIGHTOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.STOPLIGHTOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.WARNINGLIGHTOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.RESETLIGHTOUT), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.BUTTONRESET), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.BUTTONSTOP), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGSTOP.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGSTOP.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGSTOP.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGSTOP.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.FTRIGSTOP.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.SENSORPALLETLOADED), BOOL_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.MAXBOXES), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.MAXPUSHES), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.MAXLEVELS), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.COUNTERLEVELS), INT_P_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.R), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.PV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CV), INT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU_T.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU_T.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU_T.CLK), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU_T.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.CTULEVELS.CU_T.M), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL0.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.ENO), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.PT), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.Q), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.ET), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.STATE), SINT_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.PREV_IN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.CURRENT_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.TRIGGER0.TONADDLEVEL1.START_TIME), TIME_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.FSM2_PETRI0.EN), BOOL_ENUM},*)
(*DBG:    {&(FSM1_RES__INSTANCE0.FSM2_PETRI0.ENO), BOOL_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               232*)
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
(*DBG:    case SINT_ENUM:*)
(*DBG:        return sizeof(SINT);*)
(*DBG:    case INT_ENUM:*)
(*DBG:    case INT_P_ENUM:*)
(*DBG:        return sizeof(INT);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:    case BOOL_P_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return sizeof(TIME);*)
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
(*DBG:    case SINT_ENUM:*)
(*DBG:        return (void *)&((__IEC_SINT_t *) ptr)->value;*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return (void *)&((__IEC_INT_t *) ptr)->value;*)
(*DBG:    case INT_P_ENUM:*)
(*DBG:        return (void *)((((__IEC_INT_p *) ptr)->flags & __IEC_FORCE_FLAG) *)
(*DBG:                        ? &(((__IEC_INT_p *) ptr)->fvalue) *)
(*DBG:                        : ((__IEC_INT_p *) ptr)->value);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    case BOOL_P_ENUM:*)
(*DBG:        return (void *)((((__IEC_BOOL_p *) ptr)->flags & __IEC_FORCE_FLAG) *)
(*DBG:                        ? &(((__IEC_BOOL_p *) ptr)->fvalue) *)
(*DBG:                        : ((__IEC_BOOL_p *) ptr)->value);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return (void *)&((__IEC_TIME_t *) ptr)->value;*)
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
(*DBG:        case SINT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_SINT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_SINT_t *) ptr)->value = *((SINT *) val);*)
(*DBG:            ((__IEC_SINT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
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
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case SINT_ENUM:*)
(*DBG:            ((__IEC_SINT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_ENUM:*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_P_ENUM:*)
(*DBG:            ((__IEC_INT_p *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_P_ENUM:*)
(*DBG:            ((__IEC_BOOL_p *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case TIME_ENUM:*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
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