Select * from (
select #count(distinct fk_resident_id)
   a.id, a.v_title,a.fk_facility_id,
   departments.v_name as "Department",
   if(dimensions.v_name is null, "None", dimensions.v_name) as "Dimension Name", event_dimensions.i_percentage as "Dimension Percentage",
   if(service_levels.v_name is null, "None", service_levels.v_name) as "Service Level",
   CONCAT(residents.v_first_name, " ", residents.v_last_name) as "Attendee",
residents.id as ResidentId,
care_login.event_attendance.i_present as "Present?",
   if(care_login.care_level_lookup.v_name is null, "None", care_login.care_level_lookup.v_name) as "Attendee Service Level",
   from_unixtime(case when care_login.activity_instances.i_occurrence_timestamp is not null then care_login.activity_instances.i_occurrence_timestamp else i_occurrence_id end) as StartedDate
from care_login.activities a
join care_views_dwh.mvTenantFacility tf on tf.FacilityId=a.fk_facility_id
# activity_instances join
left join care_login.activity_instances on activity_instances.fk_activity_id = a.id and (activity_instances.i_occurrence_timestamp between unix_timestamp("2023-11-13 00:00:00") and unix_timestamp("2023-11-13 23:59:59")) and activity_instances.i_occurrence_timestamp not in (select i_occurrence_id from care_login.activities where fk_parent_event_id = a.id and i_occurrence_id between unix_timestamp("2023-11-13 00:00:00") and unix_timestamp("2023-11-13 23:59:59"))
# Categories Joins
left join care_login.event_departments on event_departments.fk_event_id = a.id and v_event_table = 'activities'
left join care_login.departments on departments.id = event_departments.fk_department_id and departments.fk_facility_id IN (select FacilityId from care_views_dwh.mvTenantFacility where tf.TenantId = 489 and tf.IsTestFCT = 0 and tf.ContractEndUTS is null)

# Dimension of Wellness Joins
left join care_login.event_dimensions on event_dimensions.fk_event_id = a.id and event_dimensions.i_percentage != 0 and event_dimensions.v_event_table = 'activities'
left join care_login.dimensions  on dimensions.id = event_dimensions.fk_dimension_id

# Service Level Joins
left join care_login.event_service_levels on event_service_levels.fk_event_id = a.id and event_service_levels.v_event_table = 'activities'
left join care_login.service_levels  on service_levels.id = event_service_levels.fk_service_level_id

# Attendees
left join care_login.event_attendance on event_attendance.fk_event_id = a.id
left join care_login.users as residents on residents.id = event_attendance.fk_resident_id
left join care_login.users_profile as resident_profile on resident_profile.fk_user_id = residents.id
left join care_login.care_level_lookup on resident_profile.fk_care_level_id = care_level_lookup.id


where
# Date Filter
(
   (i_started_date >= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 1 and rec_type != "none") # x1 (instance)
OR (i_started_date >= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 0) # x1 (regular)
OR (i_started_date <= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date >= unix_timestamp("2023-11-13 23:59:59") and is_rec = 0) # x4 (regular)
OR (i_started_date <= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date >= unix_timestamp("2023-11-13 23:59:59") and is_rec = 1 and rec_type != "none") # x4 (instance)
OR (i_started_date >= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 1 and rec_type != "none") # x2 (instance)
OR (i_started_date >= unix_timestamp("2023-11-13 00:00:00") AND i_started_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 0) # x2 (regular)
OR (i_started_date >= unix_timestamp("2023-11-13 00:00:00") AND i_started_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 1 and rec_type != "none") # x2 (instance)
OR (i_ended_date >= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 0) # x3 (regular)
OR (i_ended_date >= unix_timestamp("2023-11-13 00:00:00") AND i_ended_date <= unix_timestamp("2023-11-13 23:59:59") and is_rec = 1 and rec_type != "none") # x3 (instance)
)
AND (a.is_rec = 0 or (a.is_rec = 1 and (activity_instances.fk_activity_id is not null or a.fk_parent_event_id != 0)))
# Categories Filter
# event_departments.fk_department_id = ?

# Dimensions Filter
# event_dimensions.fk_dimension_id = ?

# Service Levels Filter
# event_service_levels.fk_service_level_id = ?

# Attendee Service Level
# resident_profile.fk_care_level_id = ?


# Facility Filter
 AND tf.TenantId = 489 and tf.IsTestFCT = 0 and tf.ContractEndUTS is null) s 
   where cast(s.StartedDate as date) >= cast(@StartDate as date)
-- and i_present = "present"

 -- order by v_title;
