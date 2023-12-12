select * from (
select 
	series.id as sId,
	a.fk_parent_event_id as pid,
   a.id, a.v_title,a.fk_facility_id,
   departments.v_name as "Department",
   dimensions.v_name as "Dimension Name", event_dimensions.i_percentage as "Dimension Percentage",
   service_levels.v_name as "Service Level",
   CONCAT(residents.v_first_name, " ", residents.v_last_name) as "Attendee", event_attendance.i_present as "Present?",
   care_level_lookup.v_name as "Attendee Service Level",
   from_unixtime(case when a.is_rec = 0 then a.i_started_date else (case when activity_instances.i_occurrence_timestamp is not null then activity_instances.i_occurrence_timestamp else a.i_occurrence_id end) end) as occurrenceTime
from activities a 

# activity_instances join
left join activity_instances on activity_instances.fk_activity_id = a.id and (activity_instances.i_occurrence_timestamp between 1701846000 and 1701932399) and activity_instances.i_occurrence_timestamp not in (select i_occurrence_id from activities where fk_parent_event_id = a.id and i_occurrence_id between 1701846000 and 1701932399)
# Categories Joins
left join event_departments on event_departments.fk_event_id = a.id and v_event_table = 'activities'
left join departments on departments.id = event_departments.fk_department_id and departments.fk_facility_id IN (103)

# Dimension of Wellness Joins
left join event_dimensions on event_dimensions.fk_event_id = a.id and event_dimensions.i_percentage != 0 and event_dimensions.v_event_table = 'activities'
left join dimensions  on dimensions.id = event_dimensions.fk_dimension_id

# Service Level Joins
left join event_service_levels on event_service_levels.fk_event_id = a.id and event_service_levels.v_event_table = 'activities'
left join service_levels  on service_levels.id = event_service_levels.fk_service_level_id

# Attendees
left join event_attendance on event_attendance.fk_event_id = a.id
left join users as residents on residents.id = event_attendance.fk_resident_id
left join users_profile as resident_profile on resident_profile.fk_user_id = residents.id
left join care_level_lookup on resident_profile.fk_care_level_id = care_level_lookup.id
# left join series if instance is within date range
left join activities as series on series.id = a.fk_parent_event_id and a.i_occurrence_id between series.i_started_date and series.i_ended_date

where
# Date Filter
(
   (a.i_started_date >= 1701846000 AND a.i_ended_date <= 1701932399 and a.is_rec = 1 and a.rec_type != "none") # x1 (instance)
OR (a.i_started_date >= 1701846000 AND a.i_ended_date <= 1701932399 and a.is_rec = 0  and a.rec_type != "none") # x1 (regular)
OR (a.i_started_date <= 1701846000 AND a.i_ended_date >= 1701932399 and a.is_rec = 0  and a.rec_type != "none") # x4 (regular)
OR (a.i_started_date <= 1701846000 AND a.i_ended_date >= 1701932399 and a.is_rec = 1 and a.rec_type != "none") # x4 (instance)
OR (a.i_started_date >= 1701846000 AND a.i_ended_date <= 1701932399 and a.is_rec = 1 and a.rec_type != "none") # x2 (instance)
OR (a.i_started_date >= 1701846000 AND a.i_started_date <= 1701932399 and a.is_rec = 0  and a.rec_type != "none") # x2 (regular)
OR (a.i_started_date >= 1701846000 AND a.i_started_date <= 1701932399 and a.is_rec = 1 and a.rec_type != "none") # x2 (instance)
OR (a.i_ended_date >= 1701846000 AND a.i_ended_date <= 1701932399 and a.is_rec = 0  and a.rec_type != "none") # x3 (regular)
OR (a.i_ended_date >= 1701846000 AND a.i_ended_date <= 1701932399 and a.is_rec = 1 and a.rec_type != "none") # x3 (instance)
)
AND
# exclude instance that are outside of series date range
(a.fk_parent_event_id = 0 or series.id is not null)
# exclude series events 
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
 AND a.fk_facility_id IN (1905)
) s where s.occurrenceTime <= @startdate
