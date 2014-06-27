global with sharing class ScheduleNewEvents implements Schedulable{
	//public static String CRON_EXP = '0 50 15 * * ?'; 
	//public static String JOB_NAME = 'Schedule New Event-Hourly: '+System.now();
    global void execute(SchedulableContext ctx) {
    	String day = string.valueOf(system.now().day());
	    String month = string.valueOf(system.now().month());
	    String hour = string.valueOf(system.now().hour());
	    String minute = string.valueOf(system.now().addMinutes(1).minute());
	    String second = string.valueOf(system.now().second());
	    String year = string.valueOf(system.now().year());
	    String JOB_NAME = 'Schedule New Event : ' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
	    String CRON_EXP = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
	    System.schedule(JOB_NAME, CRON_EXP, new ScheduleNewEvents());
        ScheduleEventHandler.fetchNewEvent();
    }   
}