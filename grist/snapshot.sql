-- Grist document snapshot (diffable). Regenerate: python3 grist/sync.py dump
-- source: meal.grist
-- Grist internal helper columns (gristHelper_*, manualSort) are omitted.

-- B1_Community_Check
CREATE TABLE B1_Community_Check (id, B1, Community, Submission, Community_self_governance, Territorial_management, Revitalisation_culture_knowledge, Mobilisation_against_threats, Conflict_resolution_significant, Supporting_land_claims, Community_conservation_or_restoration, Livelihoods_initiatives, Gender, Mapping, Supporting_community_participation_in_national_processes, Supporting_community_participation_in_international_processes, Food_systems, Key, Duplicate);
INSERT INTO B1_Community_Check VALUES (1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 'B1_Work_on_the_ground[1]:Community[1]', 0);
INSERT INTO B1_Community_Check VALUES (2, 1, 2, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 'B1_Work_on_the_ground[1]:Community[2]', 0);
INSERT INTO B1_Community_Check VALUES (3, 1, 3, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 'B1_Work_on_the_ground[1]:Community[3]', 0);
INSERT INTO B1_Community_Check VALUES (4, 1, 4, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 'B1_Work_on_the_ground[1]:Community[4]', 0);
INSERT INTO B1_Community_Check VALUES (5, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 'B1_Work_on_the_ground[2]:Community[2]', 0);
INSERT INTO B1_Community_Check VALUES (6, 2, 4, 2, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 'B1_Work_on_the_ground[2]:Community[4]', 0);
INSERT INTO B1_Community_Check VALUES (7, 2, 5, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 'B1_Work_on_the_ground[2]:Community[5]', 0);

-- B1_Work_on_the_ground
CREATE TABLE B1_Work_on_the_ground (id, Community_self_governance, Territorial_management, Revitalisation_of_culture_intergenerational_transmission_of_knowledge, Mobilisation_against_threats, Conflict_resolution_impacting_on_a_significant_portion_of_the_community, Supporting_land_claims, Community_conservation_or_restoration, Livelihoods_initiatives, Gender, Mapping, Supporting_community_participation_in_national_processes, Supporting_community_participation_in_international_processes, Food_systems, Other, Submission, Submission_Period);
INSERT INTO B1_Work_on_the_ground VALUES (1, '[1,2,3]', '[1,2,3]', '[1,2,3]', NULL, '[1,2,3]', '[1,2,3,4]', '[4]', '[3]', '[2,4]', '[1,3]', NULL, NULL, '[1]', '', 1, '2026 - Semester 1 - Test Team');
INSERT INTO B1_Work_on_the_ground VALUES (2, '[2]', '[2,4]', '[2]', NULL, NULL, NULL, NULL, NULL, '[4]', '[2,5]', NULL, NULL, NULL, '', 2, '2026 - Semester 2 - Test Team');

-- B2_Threat
CREATE TABLE B2_Threat (id, Oil_palm, Forestry_concessions, Minerals_and_energy, Carbon_and_biodiversity_markets, Conservation_areas, Other_industrial_agriculture, Other_local_small_scale_agriculture, Other_encroachment_by_neighbours_or_external_parties, Armed_conflict_actors, Infrastructure_roads_railways_energy_, Submission_B2);

-- B4_Participation_per_group
CREATE TABLE B4_Participation_per_group (id, Submission, Women, Men, Transgender_other_gender_identities_if_applicable_, Youth, Elders);

-- B5_Comments
CREATE TABLE B5_Comments (id, Submission, Comments);

-- C1_Regulatory_Standards_Work
CREATE TABLE C1_Regulatory_Standards_Work (id, Submission, Name, Level, Active, Witnessed_change, Overall_Participation, Women_Participation, Youth_Participation, Overall_Influence, Women_Influence, Youth_Influence);

-- C2_Audit_Standards_Review
CREATE TABLE C2_Audit_Standards_Review (id, Name, Independence, Transparency, Human_rights_expertise_of_auditors_verifiers, Effective_community_participation, Grievance_mechanisms, Other_changes_brief_description_, Submission);

-- C3_Bio_Climate_Finance_Log
CREATE TABLE C3_Bio_Climate_Finance_Log (id, Submission, Description, Target_actors, Topics_addressed, Direct_community_representation, Notes);

-- C4_Human_Rights_mechanisms
CREATE TABLE C4_Human_Rights_mechanisms (id, Submission, Description, Nature_of_change);

-- C5_Self_determined_conservation
CREATE TABLE C5_Self_determined_conservation (id, Submission, Summary, Evaluation_of_change);

-- C6_Publications_and_communications
CREATE TABLE C6_Publications_and_communications (id, Submission, Name, Link, Type, Other_type, Topic);

-- Community
CREATE TABLE Community (id, Name, Population, Latitude, Is_Confidential, Hectares, Partner, Longitude, Map_Link, Population_men, Population_women, Population_other, Population_youth, Country, Leadership_men, Leadership_women, Leadership_other, Leadership_youth, Leadership_elder, Map_iframe, Submission);
INSERT INTO Community VALUES (1, 'Test Community Alpha', 0, 0, '', 0, NULL, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', '[1]');
INSERT INTO Community VALUES (2, 'Test Community Beta', 0, 0, '', 0, NULL, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', '[1,2]');
INSERT INTO Community VALUES (3, 'Test Community Gamma', 0, 0, '', 0, NULL, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', '[1]');
INSERT INTO Community VALUES (4, 'Test Community Delta', 0, 0, '', 0, NULL, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', '[1,2]');
INSERT INTO Community VALUES (5, 'Test Community Echo', 0, 0, '', 0, NULL, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', '[2]');

-- Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth
CREATE TABLE Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth (id, Name, Population, Latitude, Map_Link, Hectares, Partner, Longitude, Population_men, Population_women, Population_other, Population_youth, Country, Map_iframe, Leadership_men, Leadership_women, Leadership_other, Leadership_youth, Leadership_elder, group, count);
INSERT INTO Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth VALUES (1, 'Test Community Alpha', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', 0, 0, 0, 0, 0, '[1]', 1);
INSERT INTO Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth VALUES (2, 'Test Community Beta', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', 0, 0, 0, 0, 0, '[2]', 1);
INSERT INTO Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth VALUES (3, 'Test Community Gamma', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', 0, 0, 0, 0, 0, '[3]', 1);
INSERT INTO Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth VALUES (4, 'Test Community Delta', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', 0, 0, 0, 0, 0, '[4]', 1);
INSERT INTO Community_summary_Country_Hectares_Latitude_Leadership_elder_Leadership_men_Leadership_other_Leadership_women_Leadership_youth_Longitude_Map_Link_Map_iframe_Name_Partner_Population_Population_men_Population_other_Population_women_Population_youth VALUES (5, 'Test Community Echo', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, '<iframe style=''width: 100%; height: 100%; border: none; display: block;'' src=''''></iframe>', 0, 0, 0, 0, 0, '[5]', 1);

-- Country
CREATE TABLE Country (id, Partners, Allies, Activities, Threats, Cases_and_Complaints, Name, Community);

-- D2_Land_Rights_Reform_Law_Policy
CREATE TABLE D2_Land_Rights_Reform_Law_Policy (id, Submission, Name, Category, Nature_of_change, Description);

-- D3_Advocacy_topic_work
CREATE TABLE D3_Advocacy_topic_work (id, Submission, Category, Nature_of_change, Description);

-- D4_Category_significant_changes
CREATE TABLE D4_Category_significant_changes (id, Submission, Category, Nature_of_change);

-- D5A_Finalized_tools_or_instruments
CREATE TABLE D5A_Finalized_tools_or_instruments (id, Submission, Community, Type, Other_Entity);

-- D5B_Non_state_respect
CREATE TABLE D5B_Non_state_respect (id, Submission, Other_entity, Name, Name_of_process, Description, Community);

-- D6_National_level_work_on_corporate_laws
CREATE TABLE D6_National_level_work_on_corporate_laws (id, Submission, awareness_raising_or_training_of_civil_society, awareness_raising_or_training_of_communities, awareness_raising_or_training_of_government, awareness_raising_or_training_of_judiciary, awareness_raising_or_training_of_national_human_rights_institutions, awareness_raising_or_training_of_business, supporting_partner_civil_society_community_advocacy_and_campaigning, research_and_policy_analysis, engaging_with_or_supporting_partners_to_engage_with_national_action_plans_on_business_and_human_rights, facilitating_dialogue_between_stakeholders, developing_a_legislative_model, engaging_with_government_law_reform_on_corporate_accountability, Other);

-- D8_Resolution_mechanisms
CREATE TABLE D8_Resolution_mechanisms (id, Submission, Name, Target_of_advocacy, Mechanism, Notes);

-- D_Case_and_Complaint_category_and_body
CREATE TABLE D_Case_and_Complaint_category_and_body (id, Category, Body);

-- D_Outcome_harvesting
CREATE TABLE D_Outcome_harvesting (id, Time_period_this_outcome_refers_to, Group_in_which_the_change_took_place_select_from_dropdown_list_, Category_of_change_select_from_dropdown_list_, Level_of_change, Country_in_which_the_change_took_place_if_relevant_, Positive_or_negative_change, Expected_or_unexpected_change, Name_of_community_people_organisation_or_institution_where_change_occurred_free_text_, Description_of_change, Baseline, Description_of_FPP_s_contribution_to_the_change, Was_there_a_significant_gender_aspect_of_the_change_documented_to_note_even_if_the_main_category_of_change_was_not_gender_and_social_inclusion_, Name_of_programme, Relevant_Strategic_Priority, Is_the_outcome_confidential_or_not_, Date_of_information_entry, Name_of_outcome_harvester);

-- E_Case_and_Complaint
CREATE TABLE E_Case_and_Complaint (id, Country, Name_of_case_complaint_communication_or_submission, Category, Specific_body, Name_of_body_if_relevant_, People_or_community_concerned, Date_commenced, Key_issues_please_select_from_the_dropdown_list_, Brief_description_of_change_progress_between_July_and_December_2024_free_text_max_750_characters_, Brief_description_of_change_progress_from_January_to_June_2025_free_text_max_750_characters_, Submission, Key_issues_other);

-- F1_Exchange_meetings
CREATE TABLE F1_Exchange_meetings (id, Submission, Name, Level, Countries, Communities, Participant_total, Participant_Women, Participant_Men, Participant_other, Participant_youth, Participant_elder, Effectiveness_of_participation_of_women_in_the_meeting_or_exchange, Immediate_outcome_of_exchange, Notes);

-- F2_Alliance_building_opportunity
CREATE TABLE F2_Alliance_building_opportunity (id, Submission, Name, Level, Partners_involved, Entities_involved, Support, Total_supported, Total_supported_women, Total_supported_youth, Total_supported_men, Total_supported_other, Total_supported_elders, Did_the_engagement_have_a_thematic_focus_on_gender_or_youth_);

-- F3_University_Collaborations
CREATE TABLE F3_University_Collaborations (id, Submission, Name, Communities_involved, University_or_centre_of_learning_involved, Participants, Participation_Women, Participation_Men, Participation_Other, Participation_Youth, Participation_Elders, Thematic_focus, Notes);

-- F4_Rapid_response_support
CREATE TABLE F4_Rapid_response_support (id, Submission, Case, Support_grouping, Support_anticipation, Support_type, Has_the_support_enabled_the_human_rights_defender_s_to_continue_their_work_);

-- F5_Advocacy_for_direct_funding
CREATE TABLE F5_Advocacy_for_direct_funding (id, Submission, Instance_and_target_of_advocacy, If_joint_advocacy_please_provide_the_name_of_the_organisation_s_);

-- F6_Partner_capacity_building
CREATE TABLE F6_Partner_capacity_building (id, Submission, Name, Partner, Focus_of_support, Focus_other, Who_provided_the_support_, Type_of_support, Type_other, Participants_total, Participants_Women, Participants_Men, Participants_other, Participants_youth, Participants_elders);

-- Old_Activity
CREATE TABLE Old_Activity (id, Type, Community, When, Self_governance);

-- Old_Ally
CREATE TABLE Old_Ally (id, Name, B, C);

-- PAGE_A_Introductory_Information
CREATE TABLE PAGE_A_Introductory_Information (id, Introduction, B, C);

-- PAGE_B3_Participation_Data
CREATE TABLE PAGE_B3_Participation_Data (id, Text, B, C);

-- PAGE_B_Strong_communities
CREATE TABLE PAGE_B_Strong_communities (id, Introduction, B, C);

-- PAGE_C_Processes
CREATE TABLE PAGE_C_Processes (id, A, B, C);

-- PAGE_D_Legal_Systems
CREATE TABLE PAGE_D_Legal_Systems (id, A, B, C);

-- PAGE_F_Resilient_networks_and_movements
CREATE TABLE PAGE_F_Resilient_networks_and_movements (id, A, B, C);

-- PAGE_MEAL_ADMIN
CREATE TABLE PAGE_MEAL_ADMIN (id, Text1, B, C);

-- PageViews
CREATE TABLE PageViews (id, Page, User, Viewed_At);

-- Partner
CREATE TABLE Partner (id, Name, Notes, Is_this_a_financial_partner_, if_financial_is_it_a_women_organization_, if_financial_is_youth_organization_, Submission);

-- Partner_summary_Is_this_a_financial_partner__Name_Notes_if_financial_is_it_a_women_organization__if_financial_is_youth_organization_
CREATE TABLE Partner_summary_Is_this_a_financial_partner__Name_Notes_if_financial_is_it_a_women_organization__if_financial_is_youth_organization_ (id, Name, Notes, Is_this_a_financial_partner_, if_financial_is_it_a_women_organization_, if_financial_is_youth_organization_, group, count);

-- Period
CREATE TABLE Period (id, Name, Year, Half, Active);
INSERT INTO Period VALUES (1, '2026 - Semester 1', 2026, '1', 1);
INSERT INTO Period VALUES (2, '2026 - Semester 2', 2026, '2', 1);

-- Publication
CREATE TABLE Publication (id, A, B, C);

-- Submission
CREATE TABLE Submission (id, Period, Team, Team_members, Date_of_completion, Submission_name, Link_to_Submission, A_Completed, B_completed, Communities, Partners, B1, B2);
INSERT INTO Submission VALUES (1, 1, 1, NULL, 1789430400, '2026 - Semester 1 - Test Team', 'Open Record http://localhost:47478/o/docs/jrP3kqTf6nSB/MEAL3-flip-test/p/37#a1.s232.r1', 0, 0, '[1,2,3,4]', NULL, 1, 0);
INSERT INTO Submission VALUES (2, 2, 1, NULL, 1789430400, '2026 - Semester 2 - Test Team', 'Open Record http://localhost:47478/o/docs/jrP3kqTf6nSB/MEAL3-flip-test/p/37#a1.s232.r2', 0, 0, '[2,4,5]', NULL, 2, 0);

-- Team
CREATE TABLE Team (id, Name, Country, Team_name, Active);
INSERT INTO Team VALUES (1, 'Test Team', 'Testland', 'Test Team', 1);

-- Team_member
CREATE TABLE Team_member (id, Name, Email, Team, Last_seen);

-- UserPing
CREATE TABLE UserPing (id, User_Email);

