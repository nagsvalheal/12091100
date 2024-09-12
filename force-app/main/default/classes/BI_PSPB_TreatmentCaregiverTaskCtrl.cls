public class BI_PSPB_TreatmentCaregiverTaskCtrl {
public List<Id> enrolleeRecIds;
	public List<Id> enrolleePastOne;
	public List<Id> enrolleePastThree;
    public String userType;
	public Id caregiverId;

    // Constructor to initialize all parameters
    public BI_PSPB_TreatmentCaregiverTaskCtrl(
        List<Id> enrolleeRecIds,
		List<Id> enrolleePastOne,
		List<Id> enrolleePastThree,
		String userType,
		Id caregiverId
    ) {
        this.enrolleeRecIds = enrolleeRecIds;
        this.enrolleePastOne = enrolleePastOne;
        this.enrolleePastThree = enrolleePastThree;
        this.userType = userType;
        this.caregiverId = caregiverId;
    }
}