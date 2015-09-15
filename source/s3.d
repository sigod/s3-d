module s3;

private {
	import std.exception : enforce;
	import std.range;
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
		import helpers.rfc822date;
		import std.datetime;
		import std.net.curl;

		auto client = HTTP(request.bucket ~ "." ~ endpoint ~ request.key);

		client.method = HTTP.Method.put;

		auto date = Clock.currTime(UTC()).toRFC822DateTime();

		assert(request.content_size <= uint.max, "uploading files bigger than uint.max isn't supported yet");

		client.contentLength = cast(uint)request.content_size;
		client.addRequestHeader("Date", date);
		client.addRequestHeader("x-amz-acl", "public-read");
		client.addRequestHeader("Content-Type", "image/jpeg");
		client.addRequestHeader("Authorization",
			_authHeader("PUT", "", "image/jpeg", date, _cannedResource(request.bucket, request.key), "x-amz-acl:public-read")
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

	private string _authHeader(string method, string md5, string type, string date, string cannedResource, string x_amz = "")
	{
		import helpers.hmac;
		import std.base64;
		import std.format : format;
		import std.utf : toUTF8;
		import std.string : representation;

		string part = format("%s\n%s\n%s\n%s\n", method, md5, type, date);
		string signature = Base64.encode(hmac_sha1(
			_secret_key.representation,
			toUTF8(part ~ (x_amz == "" ? "" : x_amz ~ "\n") ~ cannedResource).representation
		));

		return format("AWS %s:%s", _access_key, signature);
	}

	private string _cannedResource(string bucket, string key)
	{
		return "/" ~ bucket ~ key;
	}
}

struct PutObjectRequest(Range)
	if (isInputRange!Range && is(ElementType!Range == ubyte[]))
{
	string bucket;
	string key;
	Range content;
	uint content_size;
}

auto putObjectRequest(string bucket, string key, string file)
{
	import std.stdio : File;

	enum chunk_size = 16 * 1024; // 16 KiB
	auto file_ = File(file, "r");

	return PutObjectRequest!(File.ByChunk)(bucket, key, file_.byChunk(chunk_size), cast(uint)file_.size);
}
