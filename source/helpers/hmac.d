module helpers.hmac;

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
