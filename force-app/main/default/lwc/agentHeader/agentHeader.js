import { LightningElement, api, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CometD from "@salesforce/resourceUrl/cometD";
import fetchSessionId from '@salesforce/apex/AgentUtil.fetchSessionId';
import enrollPatientInTrial from '@salesforce/apex/TrialEnrollmentController.enrollPatientInTrial';
import {
    MessageContext,
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    publish
} from 'lightning/messageService';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AgentLMS from "@salesforce/messageChannel/AgentLMS__c";
import userID from '@salesforce/user/Id';
import { NavigationMixin } from "lightning/navigation";

export default class NyulhGetRecords extends NavigationMixin(LightningElement) {
    subscription;
    sessionId;
    pageName;
    platformEventPayload;
    @track eligibleTrials = [];
    @track showTrialsTable = false;
    currentUserID ='';
    @track isEnrolling = false;
    @track enrollingTrialName = '';

    @wire(MessageContext)
    messageContext;

    @wire(fetchSessionId)
    async wiredSessionId({ error, data }) {
        try {
            if (data) {
                const self = this;
                this.sessionId = data;
                await loadScript(this, CometD);
                const cometDLib = new window.org.cometd.CometD();
                cometDLib.configure({
                    url: `${window.location.protocol}//${window.location.hostname}/cometd/62.0/`,
                    requestHeaders: {
                        Authorization: `OAuth ${this.sessionId}`
                    },
                    appendMessageTypeToURL: false,
                    logLevel: 'debug'
                });
                cometDLib.websocketEnabled = false;
                cometDLib.handshake(function (status) {
                    console.log('Status is', JSON.stringify(status));
                    if (status.successful) {
                        cometDLib.subscribe("/event/AgentActionEvent__e", function (message) {
                            console.log("message --", JSON.stringify(message));
                            if (message && message.data && message.data.payload) {
                                console.log("message.data.payload --", JSON.stringify(message.data.payload));
                                let payload = message.data.payload;
                                
                                // Process Studies_JSON__c if it exists
                                if (payload.Studies_JSON__c) {
                                    self.processStudiesJson(payload.Studies_JSON__c);
                                }
                            }
                        });
                    } else {
                        console.error('Error in handshaking:', JSON.stringify(status));
                    }
                });
            } else if (error) {
                console.log('Error occurred in getting session id', JSON.stringify(error));
                this.sessionId = undefined;
            }
        } catch (err) {
            console.error(err);
        }
    }

    processStudiesJson(studiesJsonString) {
        try {
            const studiesData = JSON.parse(studiesJsonString);
            
            // Check if LoggedInUserID matches current user's ID
            if (studiesData.LoggedInUserID === this.currentUserID) {
                if (studiesData.EligibleTrials && Array.isArray(studiesData.EligibleTrials)) {
                    // Process trials to convert arrays to formatted strings and preserve arrays for the card view
                    this.eligibleTrials = studiesData.EligibleTrials.map(trial => {
                        // Create a copy of the trial
                        const processedTrial = {...trial};
                        
                        // Convert null or undefined arrays to empty arrays
                        if (!processedTrial.CreteriaMatched) {
                            processedTrial.CreteriaMatched = [];
                        }
                        if (!processedTrial.CreteriaNotMatched) {
                            processedTrial.CreteriaNotMatched = [];
                        }
                        
                        // Add string representations for the legacy view
                        processedTrial.criteriaMatchedString = processedTrial.CreteriaMatched.join(', ');
                        processedTrial.criteriaNotMatchedString = processedTrial.CreteriaNotMatched.join(', ');
                        
                        return processedTrial;
                    });
                    this.showTrialsTable = this.eligibleTrials.length > 0;
                    console.log('Eligible trials found:', JSON.stringify(this.eligibleTrials));
                } else {
                    console.log('No eligible trials found or invalid data structure');
                    this.eligibleTrials = [];
                    this.showTrialsTable = false;
                }
            } else {
                console.log('User ID does not match. Logged in user:', studiesData.LoggedInUserID, 'Current user:', this.currentUserID);
                this.showTrialsTable = false;
            }
        } catch (error) {
            console.error('Error processing Studies JSON:', error);
            this.eligibleTrials = [];
            this.showTrialsTable = false;
        }
    }

    connectedCallback() {
        console.log('agentHeader connectedCallback');
        this.currentUserID = userID;
        console.log('currentUserID123', this.currentUserID);
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            AgentLMS,
            (message) => this.refireEvent(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    refireEvent(message) {
        if (message.componentName !== "agentHeader") {
            console.log(message);
            publish(this.messageContext, AgentLMS, { filters: this.platformEventPayload, componentName: "nyulhGetRecords" });
        }
    }

    // Handle enrollment button click
    handleEnrollClick(event) {
        // Prevent double clicks
        if (this.isEnrolling) return;
        
        this.isEnrolling = true;
        
        // Get the trial name from the button's data attribute
        const trialName = event.currentTarget.dataset.trialName;
        this.enrollingTrialName = trialName;
        
        // Call the Apex method to enroll the patient
        enrollPatientInTrial({ trialName: trialName, userId: this.currentUserID })
            .then(result => {
                // Handle success or error messages
                console.log('Enrollment result:', result);
                
                if (result.startsWith('Success')) {
                    // Show success toast
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: result,
                            variant: 'success'
                        })
                    );
                    
                    // Update UI to show enrolled status
                    this.updateTrialEnrollmentStatus(trialName);
                } else {
                    // Show error toast
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result,
                            variant: 'error'
                        })
                    );
                }
            })
            .catch(error => {
                // Handle exceptions
                console.error('Error enrolling in trial:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An error occurred while trying to enroll in the study. Please try again later.',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isEnrolling = false;
                this.enrollingTrialName = '';
            });
    }
    
    // Getter to determine if we're in an enrolling state
    get isTrialEnrolling() {
        return this.isEnrolling;
    }
    
    // Update the UI to show enrolled status
    updateTrialEnrollmentStatus(trialName) {
        this.eligibleTrials = this.eligibleTrials.map(trial => {
            if (trial.TrialName === trialName) {
                return { ...trial, isEnrolled: true };
            }
            return trial;
        });
    }
}