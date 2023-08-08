let
    TimeList = List.Times(#time(0, 0, 0), 1440, #duration(0, 0, 1, 0)),
    Source = Table.FromList(TimeList, Splitter.SplitByNothing()),
    RenamedColumns = Table.RenameColumns(Source, {{"Column1", "Time"}}),
    #"Changed Type to Time" = Table.TransformColumnTypes(RenamedColumns, {{"Time", type time}}),
    InsertHourNumber = Table.AddColumn(#"Changed Type to Time", "Hour Number", each Time.Hour([Time]), Int64.Type),
    InsertHour = Table.AddColumn(InsertHourNumber, "Hour", each Time.StartOfHour([Time]), Time.Type),
    InsertMinuteNumber = Table.AddColumn(InsertHour, "Minute Number", each Time.Minute([Time]), Int64.Type),
    InsertMinute = Table.AddColumn(
        InsertMinuteNumber, "Minute", each Value.Add([Hour], #duration(0, 0, [#"Minute Number"], 0)), Time.Type
    ),
    InsertQuarterHour = Table.AddColumn(
        InsertMinute,
        "Quarter Hour",
        each
            if [#"Minute Number"] < 15 then
                [Hour]
            else if [#"Minute Number"] < 30 then
                Value.Add([Hour], #duration(0, 0, 15, 0))
            else if [#"Minute Number"] < 45 then
                Value.Add([Hour], #duration(0, 0, 30, 0))
            else
                Value.Add([Hour], #duration(0, 0, 45, 0)),
        Time.Type
    ),
    InsertHalfHour = Table.AddColumn(
        InsertQuarterHour,
        "Half Hour",
        each if [#"Minute Number"] < 30 then [Hour] else Value.Add([Hour], #duration(0, 0, 30, 0)),
        Time.Type
    ),
    MorningStart = "07:00",
    AfternoonStart = "12:00",
    EveningStart = "17:00",
    NightStart = "22:00",
    InsertDayPeriod = Table.AddColumn(
        InsertHalfHour,
        "Day Period",
        each
            if Time.FromText(MorningStart) <= [Time] and [Time] < Time.FromText(AfternoonStart) then
                "Morning"
            else if Time.FromText(AfternoonStart) <= [Time] and [Time] < Time.FromText(EveningStart) then
                "Afternoon"
            else if Time.FromText(EveningStart) <= [Time] and [Time] < Time.FromText(NightStart) then
                "Evening"
            else
                "Night",
        Text.Type
    ),
    InsertTimeKeyMin = Table.AddColumn(InsertDayPeriod, "TimeID", each Time.ToText([Time], "HHmm"), type text),
    #"Changed Type" = Table.TransformColumnTypes(InsertTimeKeyMin, {{"TimeID", Int64.Type}}),
    #"Reordered Columns" = Table.ReorderColumns(
        #"Changed Type",
        {
            "TimeID",
            "Time",
            "Minute Number",
            "Minute",
            "Quarter Hour",
            "Half Hour",
            "Hour Number",
            "Hour",
            "Day Period"
        }
    ),
    InsertAMPM = Table.AddColumn(#"Reordered Columns", "AM/PM", each if [Hour Number] < 12 then "AM" else "PM",
    Text.Type)
in
    InsertAMPM
