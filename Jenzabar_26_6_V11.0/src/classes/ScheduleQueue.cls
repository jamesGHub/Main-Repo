/*
 * Description : A schedule class which will fetch the new queue & schedule it per every minute.
 */
global class ScheduleQueue implements Schedulable {
    
    // This method will be used to call the queuer
    global void execute(SchedulableContext ctx) {
        this.start();
        ScheduleQueueHandler.scheduleQueue();
    }  
    
    // This method will add the 1 minute to current time
    public void start()
    {
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String hour = string.valueOf(system.now().hour());
        String minute = String.valueOf(System.now().minute() + 1);
        String second = string.valueOf(system.now().second());
        String year = string.valueOf(system.now().year());
        String strJobName = 'Queue-' + second + '_' + minute + '_' + hour + '_' + day + '_' + month + '_' + year;
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        System.schedule(strJobName, strSchedule, new ScheduleQueue());
    } 
}