module helpers.rfc822date;

import std.datetime : SysTime;

// example: Tue, 27 Mar 2007 21:06:08 +0000

string toRFC822DateTime(in SysTime time) @safe
{
	import std.format : format;
	try
	{
		auto time_ = time.toUTC();

		assert(time_.year >= 1900);

		return format("%s, %02d %s %04d %02d:%02d:%02d +0000",
			dayToString(time_.dayOfWeek), time_.day, monthToString(time_.month), time_.year,
			time_.hour, time_.minute, time_.second
		);
	}
	catch(Exception e)
		assert(0, "format() threw.");
}

private:

// private members of std.datetime:

import std.datetime;

immutable string[12] _monthNames = ["Jan",
									"Feb",
									"Mar",
									"Apr",
									"May",
									"Jun",
									"Jul",
									"Aug",
									"Sep",
									"Oct",
									"Nov",
									"Dec"];

string monthToString(Month month) @safe pure
{
	import std.format : format;
	assert(month >= Month.jan && month <= Month.dec, format("Invalid month: %s", month));
	return _monthNames[month - Month.jan];
}

unittest
{
	assert(monthToString(Month.jan) == "Jan");
	assert(monthToString(Month.feb) == "Feb");
	assert(monthToString(Month.mar) == "Mar");
	assert(monthToString(Month.apr) == "Apr");
	assert(monthToString(Month.may) == "May");
	assert(monthToString(Month.jun) == "Jun");
	assert(monthToString(Month.jul) == "Jul");
	assert(monthToString(Month.aug) == "Aug");
	assert(monthToString(Month.sep) == "Sep");
	assert(monthToString(Month.oct) == "Oct");
	assert(monthToString(Month.nov) == "Nov");
	assert(monthToString(Month.dec) == "Dec");
}

// custom

immutable string[7] daysOfWeekNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

string dayToString(DayOfWeek day) @safe pure
{
	return daysOfWeekNames[day - DayOfWeek.sun];
}

unittest
{
	assert(dayToString(DayOfWeek.sun) == "Sun");
	assert(dayToString(DayOfWeek.mon) == "Mon");
	assert(dayToString(DayOfWeek.tue) == "Tue");
	assert(dayToString(DayOfWeek.wed) == "Wed");
	assert(dayToString(DayOfWeek.thu) == "Thu");
	assert(dayToString(DayOfWeek.fri) == "Fri");
	assert(dayToString(DayOfWeek.sat) == "Sat");
}
