module helpers;

ubyte[20] hmac_sha1(const(ubyte)[] key, const(ubyte)[] message)
{
	import std.digest.sha : sha1Of;

	enum block_size = 64;

	if (key.length > block_size)
		key = sha1Of(key);
	if (key.length < block_size)
		key.length = block_size;

	ubyte[] o_key_pad = key.dup;
	ubyte[] i_key_pad = key.dup;

	o_key_pad[] ^= 0x5c;
	i_key_pad[] ^= 0x36;

	return sha1Of(o_key_pad ~ sha1Of(i_key_pad ~ message));
}

unittest {
	import std.digest.digest : toHexString;

	auto value = hmac_sha1(cast(ubyte[])"", cast(ubyte[])"");
	assert(value.toHexString == "FBDB1D1B18AA6C08324B7D64B71FB76370690E1D");

	value = hmac_sha1(cast(ubyte[])"key", cast(ubyte[])"The quick brown fox jumps over the lazy dog");
	assert(value.toHexString == "DE7C9B85B8B78AA6BC8A7A36F70A90701C9DB4D9");
}


private import std.datetime : SysTime;

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
