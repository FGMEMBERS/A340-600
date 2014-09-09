#############################################################################
# A340 Autopilot Flight Director System
# Syd Adams
#speed modes  = THR,THR REF, IDLE,HOLD,SPD;
# roll modes = HDG SEL,HDG HOLD, LNAV,LOC,ROLLOUT,TO/GA,TRK SEL, TRK HOLD,ATT;
# pitch modes TO/GA,ALT,V/S,VNAV PTH,VNAV SPD,VNAV ALT,G/S,FLARE,FLCH SPD,FPA;
# FPA range: -9.9 ~ 9.9 degrees
# VS range : -8000 ~ 6000
# ALT range  : 0 ~ 50,000
#
#############################################################################

#Usage : var afds = AFDS.new();

var AFDS = {
    new : func{
        var m = {parents:[AFDS]};

        m.spd_list=["","THR","THR REF","HOLD","IDLE","SPD"];

        m.roll_list=["","HDG SEL","HDG HOLD",
        "LNAV","LOC","ROLLOUT","TO/GA","TRK SEL",
        "TRK HOLD","ATT"];

        m.pitch_list=["","TO/GA","ALT","V/S","VNAV PTH","VNAV SPD",
        "VNAV ALT","G/S","FLARE","FLCH SPD","FPA"];

        m.mach_enabled=0;
        m.trk_enabled=0;
        m.fpa_enabled=0;
        m.lnav_active=0;
        m.vnav_active=0;
        m.fms_active=0;
        m.vor_armed=0;
        m.gs_armed=0;

        m.current_speed_mode=0;
        m.current_roll_mode=0;
        m.current_pitch_mode=0;

        m.AFDS_node = props.globals.getNode("instrumentation/afds",1);
        m.AFDS_inputs = m.AFDS_node.getNode("inputs",1);
        m.AFDS_apmodes = m.AFDS_node.getNode("ap-modes",1);
        m.AFDS_settings = m.AFDS_node.getNode("settings",1);

        m.AP = m.AFDS_inputs.initNode("AP",0,"BOOL");
        m.FD = m.AFDS_inputs.initNode("FD",0,"BOOL");
        m.at1 = m.AFDS_inputs.initNode("at-armed[0]",0,"BOOL");
        m.at2 = m.AFDS_inputs.initNode("at-armed[1]",0,"BOOL");
        m.GA_armed = m.AFDS_inputs.initNode("ga-armed",0,"BOOL");
        m.alt_knob = m.AFDS_inputs.initNode("alt-knob",0,"BOOL");
        m.auto_throttle = m.AFDS_inputs.initNode("at-hold",0,"BOOL");
        m.clb_con = m.AFDS_inputs.initNode("clb-con-hold",0,"BOOL");
        m.lnav = m.AFDS_inputs.initNode("lnav-hold",0,"BOOL");
        m.vnav = m.AFDS_inputs.initNode("vnav-hold",0,"BOOL");
        m.flch = m.AFDS_inputs.initNode("flch-hold",0,"BOOL");
        m.hdg_hold = m.AFDS_inputs.initNode("hdg-hold",0,"BOOL");
        m.vs_fpa = m.AFDS_inputs.initNode("vs-fpa-hold",0,"BOOL");
        m.alt_hold = m.AFDS_inputs.initNode("alt-hold",0,"BOOL");
        m.loc = m.AFDS_inputs.initNode("loc-hold",0,"BOOL");
        m.app = m.AFDS_inputs.initNode("app-hold",0,"BOOL");
        m.speed_src = m.AFDS_inputs.initNode("speed-src",0,"INT");
        m.ias_mach_selected = m.AFDS_inputs.initNode("ias-mach-selected",m.mach_enabled,"BOOL");
        m.hdg_trk_selected = m.AFDS_inputs.initNode("hdg-trk-selected",m.trk_enabled,"BOOL");
        m.vs_fpa_selected = m.AFDS_inputs.initNode("vs-fpa-selected",m.fpa_enabled,"BOOL");
        m.nav_src = m.AFDS_inputs.initNode("nav-src","VOR");

        m.ias_setting = m.AFDS_settings.initNode("ias",250);# 100 - 399 #
        m.mach_setting = m.AFDS_settings.initNode("mach",0.40);# 0.40 - 0.95 #
        m.hdg_setting = m.AFDS_settings.initNode("hdg",360,"INT");
        m.trk_setting = m.AFDS_settings.initNode("trk",0,"INT");
        m.vs_setting = m.AFDS_settings.initNode("vs",0); # -8000 to +6000 #
        m.fpa_setting = m.AFDS_settings.initNode("fpa",0); # -9.9 to 9.9 #
        m.alt_setting = m.AFDS_settings.initNode("altitude",10000);
        m.bank_min = m.AFDS_settings.initNode("bank-min",-30);
        m.bank_max = m.AFDS_settings.initNode("bank-max",30);
        m.auto_brake_setting = m.AFDS_settings.initNode("autobrake",0.000,"DOUBLE");
        m.vnav_alt = m.AFDS_settings.initNode("vnav-alt",35000);
        m.lnav_heading = m.AFDS_settings.initNode("lnav-mag-heading",0);

        m.AP_roll_mode = m.AFDS_apmodes.initNode("roll-mode","TO/GA");
        m.AP_roll_arm = m.AFDS_apmodes.initNode("roll-mode-arm"," ");
        m.AP_pitch_mode = m.AFDS_apmodes.initNode("pitch-mode","TO/GA");
        m.AP_pitch_arm = m.AFDS_apmodes.initNode("pitch-mode-arm"," ");
        m.AP_speed_mode = m.AFDS_apmodes.initNode("speed-mode","THR");
        m.AP_annun = m.AFDS_apmodes.initNode("mode-annunciator"," ");

        return m;
    },

####    Inputs    ####
###################
    ap_input : func(mode){
        var tmp=0;
        if(mode=="mach-toggle")
        {
            me.mach_enabled=1-me.mach_enabled;
            me.ias_mach_selected.setValue(me.mach_enabled);
        }
        elsif(mode=="trk-toggle")
        {
            me.trk_enabled=1-me.trk_enabled;
            me.hdg_trk_selected.setValue(me.trk_enabled);
        }
        elsif(mode=="fpa-toggle")
        {
            me.fpa_enabled=1-me.fpa_enabled;
            me.vs_fpa_selected.setValue(me.fpa_enabled);
        }
        elsif(mode=="th1-arm")
        {
            tmp = me.at1.getValue();
            tmp=1-tmp;
            me.at1.setValue(tmp);
        }
        elsif(mode=="th2-arm")
        {
            tmp = me.at2.getValue();
            tmp=1-tmp;
            me.at2.setValue(tmp);
        }
        elsif(mode=="alt-inc")
        {
            tmp = me.alt_setting.getValue();
            var step=me.alt_knob.getValue();
            if(step){
                tmp+=1000
            }else tmp+=100;
            if(tmp>50000)tmp=50000;
            me.alt_setting.setValue(tmp);
        }
        elsif(mode=="alt-dec")
        {
            tmp = me.alt_setting.getValue();
            var step=me.alt_knob.getValue();
            if(step){
                tmp-=1000
            }else tmp-=100;
            if(tmp<0)tmp=0;
            me.alt_setting.setValue(tmp);
        }        
    },
#####################
    ap_mode : func(apmode){
        var tmp=0;
        if(apmode=="FD")
        {
            tmp = me.FD.getValue();
            tmp=1-tmp;
            me.FD.setValue(tmp);
            var msg=" ";
            if(tmp==1)msg="FLT DIR";
            if(me.AP.getValue())msg="AP ENG";
            me.AP_annun.setValue(msg);
        }
        elsif(apmode=="AP")
        {
            tmp = me.AP.getValue();
            tmp=1-tmp;
            me.AP.setValue(tmp);
            var msg=" ";
            if(tmp==1){
                msg="AP ENG";
            }else{
                if(me.FD.getValue())msg="FLT DIR";
            }
            me.AP_annun.setValue(msg);
            var passive =1-tmp;
            setprop("autopilot/locks/passive-mode",passive);
        }
        elsif(apmode=="HDG")
        {
            tmp = me.AP_roll_mode.getValue();
            if(tmp!="HDG SEL"){
                tmp="HDG SEL";
            }else{
                tmp="";
            }
            me.AP_roll_mode.setValue(tmp);
        }
        elsif(apmode=="LNAV")
        {
            tmp = me.AP_roll_mode.getValue();
            var rt=getprop("autopilot/route-manager/route/num");
            if(rt!=0){
                me.fms_active=1;
            }else{
                me.fms_active=0;
            }
                if(tmp!="LNAV"){
                    tmp="LNAV";
                    me.lnav_active=1;
                }else{
                    tmp="";
                    me.lnav_active=0;
                }
            me.AP_roll_mode.setValue(tmp);
        }
        elsif(apmode=="VS")
        {
            tmp = me.AP_pitch_mode.getValue();
            if(me.fpa_enabled){
                if(tmp!="FPA"){
                tmp="FPA";
                }else{
                tmp="";
                }
            }else{
                if(tmp!="V/S"){
                tmp="V/S";
                }else{
                tmp="";
                }
            }
            me.AP_pitch_mode.setValue(tmp);
        }
        elsif(apmode=="VNAV")
        {
            tmp = me.AP_pitch_mode.getValue();
                if(tmp!="VNAV ALT"){
                    tmp="VNAV ALT";
                    me.vnav_active=1;
                }else{
                    tmp="";
                    me.vnav_active=0;
                }
            me.AP_pitch_mode.setValue(tmp);
        }
        elsif(apmode=="ALT")
        {
            tmp = me.AP_pitch_mode.getValue();
                if(tmp!="ALT"){
                    tmp="ALT";
                    var tmpalt =getprop("position/altitude-ft");
                    tmpalt = int(tmpalt * 0.01);
                    tmpalt =tmpalt * 100;
                    me.alt_setting.setValue(tmpalt);
                }else{
                    tmp="";
                }
            me.AP_pitch_mode.setValue(tmp);
        }
        elsif(apmode=="APP")
        {
            tmp = getprop("instrumentation/nav/has-gs");
                if(tmp){
                    me.AP_pitch_arm.setValue("G/S");
                    me.AP_roll_arm.setValue("LOC");
                    me.vor_armed=1;
                    me.gs_armed=1;
                    me.app.setValue(1);
                    me.fms_active=0;
                }else{
                    me.AP_pitch_arm.setValue("");
                    me.AP_roll_arm.setValue("");
                    me.vor_armed=0;
                    me.gs_armed=0;
                    me.app.setValue(0);
                }
            }
    },
    #####################
    set_ap : func(apmode){
    },
#####################
    pitch_wheel : func(step){
        var ptch=me.AP_pitch_mode.getValue();
        var tmp=0;
            if(ptch=="V/S"){
                tmp = me.vs_setting.getValue();
                tmp+=step*100;
                if(tmp<-8000)tmp=-8000;
                if(tmp>6000)tmp=6000;
                me.vs_setting.setValue(tmp);
            }elsif(ptch=="FPA"){
                tmp = me.fpa_setting.getValue();
                tmp+=step*0.1;
                if(tmp<-9.9)tmp=-9.9;
                if(tmp>9.9)tmp=9.9;
                me.fpa_setting.setValue(tmp);
            }
    },
#####################
    heading_bug : func(step1){
        var tmp=0;
            if(me.trk_enabled){
                tmp = me.trk_setting.getValue();
                tmp+=step1;
                if(tmp<0)tmp+=360;
                if(tmp>359)tmp-=360;
                me.trk_setting.setValue(tmp);
            }else{
                tmp = me.hdg_setting.getValue();
                tmp+=step1;
                if(tmp<1)tmp+=360;
                if(tmp>360)tmp-=360;
                me.hdg_setting.setValue(tmp);
                setprop("autopilot/settings/heading-bug-deg",tmp);
            }
    },


};
######################################

var afds = AFDS.new();

setlistener("/sim/signals/fdm-initialized", func {
    settimer(update_afds,5);
    print("AFDS System ... check");
});

var update_afds = func {
    var hdg= 0;
    var trk= 0;
    var defl= 0;
    var mag_var=0;
    if(afds.lnav_active){
        if(afds.fms_active){
            hdg=getprop("autopilot/internal/true-heading-error-deg");
        }else{
            hdg=getprop("instrumentation/nav/radials/selected-deg");
            trk=getprop("orientation/heading-magnetic-deg");
            defl=getprop("instrumentation/nav/heading-needle-deflection");
            var newhdg=hdg-trk;
            newhdg+=defl*4.5;
            if(newhdg>180)newhdg-=360;
            if(newhdg<-180)newhdg+=360;
            hdg=newhdg;
        }
        afds.lnav_heading.setValue(hdg);
    }

    if(afds.vor_armed ==1){
        if(defl< 9 and defl>-9){
            afds.AP_roll_mode.setValue(afds.AP_roll_arm.getValue());
            afds.AP_roll_arm.setValue("");
            afds.vor_armed=0;
        }
    }

    if(afds.gs_armed==1){
        var gsdefl = getprop("instrumentation/nav/gs-needle-deflection-norm");
        if(gsdefl< 0.18 and gsdefl>-0.18){
            afds.AP_pitch_mode.setValue(afds.AP_pitch_arm.getValue());
            afds.AP_pitch_arm.setValue("");
            afds.gs_armed=0;
        }
    }

settimer(update_afds, 0);
}
