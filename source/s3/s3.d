/**
	D library API for Amazon S3

	Copyright: © 2015 sigod
	License: Subject to the terms of the MIT license, as written in the included LICENSE file.
	Authors: sigod
*/
module s3.s3;

private {
	import s3.internal.helpers;

	import std.datetime : Clock, UTC;
	import std.exception : enforce;
	import std.net.curl;
	import std.range;
}

enum CannedACL : string
{
	none			 = null,
	private_		 = "private",
	publicRead		 = "public-read",
	publicReadWrite		 = "public-read-write",
	authenticatedRead	 = "authenticated-read",
	bucketOwnerRead		 = "bucket-owner-read",
	bucketOwnerFullControl	 = "bucket-owner-full-control",
	logDeliveryWrite	 = "log-delivery-write"
}

class S3Client
{
	private string _access_key;
	private string _secret_key;

	this(string access_key, string secret_key)
	{
		_access_key = access_key;
		_secret_key = secret_key;
	}

	private string endpoint = "s3.amazonaws.com";

	void putObject(R)(PutObjectRequest!R request)
	{
		auto client = HTTP(request.bucket ~ "." ~ endpoint ~ request.key);

		client.method = HTTP.Method.put;

		auto date = Clock.currTime(UTC()).toRFC822DateTime();

		static if (!__traits(compiles, { HTTP client; client.contentLength = ulong.max; })) {
			assert(request.content_size <= uint.max, "uploading files bigger than uint.max isn't supported "
								~ "under x86 platform in this version of Phobos");

			client.contentLength = cast(uint)request.content_size;
		}
		else
			client.contentLength = request.content_size;

		client.addRequestHeader("Date", date);

		if (request.acl != CannedACL.none)
			client.addRequestHeader("x-amz-acl", request.acl);

		client.addRequestHeader("Content-Type", "image/jpeg");
		client.addRequestHeader("Authorization",
			_authHeader("PUT", "", "image/jpeg", date, _cannedResource(request.bucket, request.key), request.acl)
		);

		void[] m = void;

		auto content = request.content;

		if (!content.empty)
			m = content.front;

		client.onSend = delegate size_t(void[] data)
		{
			if (content.empty) return 0;
			else if (m.length == 0) {
				content.popFront();

				if (content.empty) return 0;

				m = content.front;
			}

			size_t length = m.length > data.length ? data.length : m.length;
			if (length == 0) return 0;

			data[0 .. length] = m[0 .. length];
			m = m[length .. $];

			return length;
		};

		client.perform();

		enforce(client.statusLine.code == 200);
	}

	void deleteObject(string bucket, string key)
	{
		auto client = HTTP(bucket ~ "." ~ endpoint ~ key);

		client.method = HTTP.Method.del;

		auto date = Clock.currTime(UTC()).toRFC822DateTime();

		client.addRequestHeader("Date", date);
		client.addRequestHeader("Authorization", _authHeader("DELETE", "", "", date, _cannedResource(bucket, key)));

		client.perform();

		enforce(client.statusLine.code == 204);
	}

	private string _authHeader(string method, string md5, string type, string date, string cannedResource, string acl = null)
	{
		import std.base64;
		import std.format : format;
		import std.utf : toUTF8;
		import std.string : representation;

		string x_amx = "";
		if (acl.length)
			x_amx = "x-amz-acl:" ~ acl ~ "\n";

		string part = format("%s\n%s\n%s\n%s\n", method, md5, type, date);
		string signature = Base64.encode(hmac_sha1(
			_secret_key.representation,
			toUTF8(part ~ x_amx ~ cannedResource).representation
		));

		return format("AWS %s:%s", _access_key, signature);
	}

	private string _cannedResource(string bucket, string key)
	{
		import std.algorithm : startsWith;

		assert(key.startsWith('/'), "keys must always start with `/`");

		return "/" ~ bucket ~ key;
	}
}

struct PutObjectRequest(Range)
	if (isInputRange!Range && is(ElementType!Range == ubyte[]))
{
	string bucket;
	string key;
	Range content;
	ulong content_size;

	CannedACL acl;
}

auto putObjectRequest(string bucket, string key, string file)
{
	import std.stdio : File;

	enum chunk_size = 16 * 1024; // 16 KiB
	auto file_ = File(file, "r");

	return PutObjectRequest!(File.ByChunk)(bucket, key, file_.byChunk(chunk_size), file_.size);
}

auto putObjectRequest(R)(string bucket, string key, R range, ulong length)
{
	enum chunk_size = 16 * 1024; // 16 KiB
	auto byChunks = range.chunks(chunk_size);

	return PutObjectRequest!(typeof(byChunks))(bucket, key, byChunks, length);
}

auto putObjectRequest(R)(string bucket, string key, R range)
	if (hasLength!R)
{
	return putObjectRequest(bucket, key, range, range.walkLength);
}

unittest
{
	ubyte[] data = [1, 2, 3, 4, 5, 6, 7, 8, 9];

	assert(putObjectRequest("", "", data, data.length).content_size == data.length);
	assert(putObjectRequest("", "", data).content_size == data.length);
}
