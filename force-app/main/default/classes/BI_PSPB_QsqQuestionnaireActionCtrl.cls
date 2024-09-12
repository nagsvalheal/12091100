/**
 * @description  This class provides methods to handle QSQ
 * related operations. It processes questionnaires when videos are uploaded,
 * creates tasks, and sends notifications (SMS and email) as needed.
 * History
 * Version    Author        Date        Detail        Description
 * 1.0        Niyas         06-09-2024  Created       Refactored Version
 */
public with sharing class BI_PSPB_QsqQuestionnaireActionCtrl {

    /**
     * @description Processes QSQ questionnaires by creating tasks for due
     * assessments when a video is uploaded. It also sends notifications (SMS
     * and email) to the relevant parties.
     */
    public static void processQsqQuestionnaires() {
        try {
            List<Task> newTaskList = new List<Task>();
            List<Id> sendNotificationIds = new List<Id>(); // Initialize the list;
            Set<Id> enrolleeIds = BI_PSPB_EnrolleeProcessorCtrl.fetchEnrolleeIds();
            
            if (!enrolleeIds.isEmpty()) {
                Integer qsqCount = BI_PSPB_QuestionsDaysCountQueryCtrl.fetchQsqCount();
                List<Id> enrolleeRecIds = BI_PSPB_SymptomProcessorCtrl.processSymptomTrackers(enrolleeIds, qsqCount);
                
                if (!enrolleeRecIds.isEmpty()) {
                    List<CareProgramEnrollee> enrolleeRecords = BI_PSPB_EnrolleeProcessorCtrl.fetchEnrolleeRecords(enrolleeRecIds);

                    for (CareProgramEnrollee enrollee : enrolleeRecords) {
                        List<Id> enrolleeEmailIds = processEnrollee(enrollee, newTaskList);
                        if(!enrolleeEmailIds.isEmpty()) {
							sendNotificationIds.addAll(enrolleeEmailIds);
						}
                    }

                    BI_PSP_DatabaseOperationsUtility.insertOperation(newTaskList, BI_PSPB_QsqQuestionnaireActionCtrl.class.toString(), false);

                    sendNotifications(sendNotificationIds);
                }
            } else {
                BI_PSP_LogMessagesUtility.logError(
                    BI_PSPB_NotificationConstantsCtrl.errorMsgRecordNotFound,
                    BI_PSPB_QsqQuestionnaireActionCtrl.class.toString(),
                    false, BI_PSPB_NotificationConstantsCtrl.severityError
                );
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.logError(
                ex.getMessage(),
                BI_PSPB_QsqQuestionnaireActionCtrl.class.toString(),
                false,
                BI_PSPB_NotificationConstantsCtrl.severityError
            );
        }
    }

    /**
     * @description This method processes a single CareProgramEnrollee record to create
     * and add tasks to the newTaskList based on the enrollee's age and caregiver status.
     * @param enrollee Enrollee for the questions to retrieve.
     * @param newTaskList List of tasks that are to be created.
     */
    private static List<Id> processEnrollee(CareProgramEnrollee enrollee, List<Task> newTaskList) {
        List<Id> enrolleeEmailIds = new List<Id>();
        try {
            Date today = Date.today();
            Integer age = BI_PSPB_EnrolleeProcessorCtrl.calculateAge(enrollee.Account.BI_PSP_Birthdate__c, today);
            String patientName = enrollee.Account.Name;
            Id enrolleeId = enrollee.Id;
            Id caregiverId = BI_PSPB_CaregiverProcessorCtrl.fetchCaregiverId(enrolleeId);
            List<Id> enrolleeSendIds = BI_PSPB_AssessmentProcessorCtrl.fetchDueAssessments(new List<Id>{enrolleeId}, BI_PSPB_NotificationConstantsCtrl.qsqQuestionName);
            
            if ((age > 18 && caregiverId == null) && !enrolleeSendIds.isEmpty()) {
                enrolleeEmailIds.addAll(enrolleeSendIds);
                BI_PSPB_TaskParameterCtrl params = new BI_PSPB_TaskParameterCtrl(
                    BI_PSPB_NotificationConstantsCtrl.qsqQuestionSubject,
                    BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
                    BI_PSPB_NotificationConstantsCtrl.actionTypeQuestionnaires,
                    '',
                    BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
                );
                newTaskList.addAll(BI_PSPB_TaskCreatorCtrl.createPatientTasks(enrolleeSendIds, params, BI_PSPB_NotificationConstantsCtrl.patient, null));
            } else {
                List<Id> caregiverSendIds = BI_PSPB_AssessmentProcessorCtrl.fetchDueAssessments(new List<Id>{enrolleeId}, BI_PSPB_NotificationConstantsCtrl.qsqQuestionName);
                if (!caregiverSendIds.isEmpty()) {
                    enrolleeEmailIds.addAll(caregiverSendIds);
                    BI_PSPB_TaskParameterCtrl params = new BI_PSPB_TaskParameterCtrl(
                        BI_PSPB_NotificationConstantsCtrl.qsqQuestionSubject,
                        BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
                        BI_PSPB_NotificationConstantsCtrl.actionTypeQuestionnaires,
                        '',
                        BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
                    );
                    newTaskList.addAll(BI_PSPB_TaskCreatorCtrl.createPatientTasks(caregiverSendIds, params, BI_PSPB_NotificationConstantsCtrl.patient, caregiverId));

                    BI_PSPB_TaskParameterCtrl params2 = new BI_PSPB_TaskParameterCtrl(
                        BI_PSPB_NotificationConstantsCtrl.qsqCaregiverOne + ' ' + patientName + BI_PSPB_NotificationConstantsCtrl.qsqCaregiverTwo,
                        BI_PSPB_NotificationConstantsCtrl.actionTypeAction,
                        BI_PSPB_NotificationConstantsCtrl.actionTypeQuestionnaires,
                        '',
                        BI_PSPB_NotificationConstantsCtrl.actionTypeNotificatonTypeAction
                    );
                    newTaskList.addAll(BI_PSPB_TaskCreatorCtrl.createCaregiverTasks(caregiverSendIds, params2, BI_PSPB_NotificationConstantsCtrl.caregiver, caregiverId));
                }
            }
        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.logError(
                ex.getMessage(),
                BI_PSPB_QsqQuestionnaireActionCtrl.class.toString(),
                false,
                BI_PSPB_NotificationConstantsCtrl.severityError
            );
        }
        return enrolleeEmailIds;
    }

    /**
     * @description Method is used to send SMS and email notifications.
     */
    private static void sendNotifications(List<Id> enrolleeEmailIds) {
        try {            
            if (!enrolleeEmailIds.isEmpty()) {
                BI_PSPB_NotificationSender.sendNotifications(enrolleeEmailIds, BI_PSPB_NotificationConstantsCtrl.qsq, new List<String>{''});
            }

        } catch (Exception ex) {
            BI_PSP_LogMessagesUtility.exceptionLogMessage(
                ex.getMessage(),
                BI_PSPB_QsqQuestionnaireActionCtrl.class.getName(),
                ex
            );
        }
    }
}