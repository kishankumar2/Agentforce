# 🧠 Clinical Trials Agent – AI-Powered Patient Matching & Automation

This is a **multi-agent AI solution** built on the Salesforce platform that streamlines the clinical trial enrollment process for pharmaceutical companies. It intelligently matches patients to the most suitable clinical trials based on eligibility criteria and automates post-enrollment activities — all without manual data entry or hardcoded rules.

---

## 🔍 Overview

Clinical trials require patient matching based on specific eligibility factors (e.g., age, geography, medical conditions). Traditionally, this process is manual, error-prone, and time-consuming.

This project solves that by using:

- **AI Agents (powered by Agentforce)**
- **Salesforce Data Cloud**
- **Business documents (PDFs) for trial metadata**
- **Dynamic Lightning Web Components (LWC)**
- **Custom Apex & Flows**
- **Platform Events for real-time UI updates**

---

## 🧩 Key Components

### 1. 💬 Clinical Trial Agent (Conversation Agent)
- Accesses a **PDF document** containing trial descriptions and eligibility criteria.
- Matches the **logged-in patient** using session context variables.
- Displays a **dynamic list of recommended trials** via LWC based on matched criteria.

### 2. ⚙️ Enrollment Automation Agent (Data Trigger Agent)
- Activated upon patient enrollment.
- Refers to a **Post-Enrollment Activities PDF** stored in Data Cloud.
- Executes activities such as:
  - Creating tasks for clinical queues
  - Sending Slack notifications
  - Updating downstream systems
  - Managing study-specific workflows using **custom Apex actions**

---

## 🛠️ Technologies Used

| Component              | Tech Stack                                      |
|------------------------|-------------------------------------------------|
| Conversational Agent   | Salesforce Agentforce + Prompt Templates        |
| Data Management        | Salesforce Data Cloud                           |
| UI Integration         | Lightning Web Components (LWC)                  |
| Backend Automation     | Apex Classes, Flows, Platform Events            |
| Communication Layer    | CometD (for real-time UI updates)               |
| Document Handling      | Business PDFs uploaded and parsed in Data Cloud |

---

## ✅ Achievements

- Created a **production-ready solution** used by pharma companies.
- Enabled **dynamic UI updates** based on agent decisions using CometD and platform events.
- Delivered a **scalable, reusable framework** by allowing business documents to drive agent logic — reducing hardcoding.
- Trained agents to select trials with **at least 2 eligibility criteria matched** and highlight unmatched ones for transparency.

---

## 📈 What's Next

If given more time, the agent will be enhanced to:
- Receive **real-time data** from clinical site applications.
- Monitor patient health and raise **proactive alerts**.
- Manage ongoing communication and feedback collection.
- Support **multilingual interactions** for global trial support.

---

