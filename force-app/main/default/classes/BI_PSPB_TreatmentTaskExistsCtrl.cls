/**
* @description  This class is used to create tasks when a video is uploaded.
* It also handles calling methods to send SMS and email notifications.
* History
* Version	Author			Date		Detail		Description
* 1.0		Niyas		24-07-2024		Created		Refactored Version
*/
public with sharing class BI_PSPB_TreatmentTaskExistsCtrl {
    public static Boolean taskExists(
		BI_PSPB_Treatment_Reminder__c reminder,
		Integer daysDifference,
		BI_PSPB_TreatmentReminderDaysCtrl daysCount
	) {
		String subject;
		if (daysDifference == daysCount.before1Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.oneDayBeforeSubject;
		} else if (daysDifference == daysCount.before3Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.threeDayBeforeSubject;
		} else if (daysDifference == daysCount.before7Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.sevenDayBeforeSubject;
		} else if (daysDifference == daysCount.before10Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.tenDayBeforeSubject;
		} else if (daysDifference == daysCount.before14Day) {
			subject = BI_PSPB_NotificationConstantsCtrl.fourteenDayBeforeSubject;
		} else {
			return false; // No task to create
		}

		// Query existing tasks to see if one with the same subject and reminder ID exists
		List<Task> existingTasks = [
			SELECT Id
			FROM Task
			WHERE Subject = :subject AND WhatId = :reminder.Id
			LIMIT 1
		];

		return !existingTasks.isEmpty();
	}
}