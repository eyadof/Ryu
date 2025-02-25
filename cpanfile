requires 'perl', '>= 5.018';
requires 'parent', 0;
requires 'curry', '>= 1.001';
requires 'indirect', 0;
requires 'Future', '>= 0.42';
requires 'Future::Queue', 0;
requires 'JSON::MaybeXS';
requires 'MIME::Base64';
requires 'Text::CSV';
requires 'Scalar::Util', '>= 1.47';
requires 'Ref::Util', '>= 0.111';
requires 'List::UtilsBy', '>= 0.10';
requires 'Log::Any', '>= 1.045';
requires 'Log::Any::Adapter', '>= 1.045';
requires 'Syntax::Keyword::Try', '>= 0.04';
requires 'Encode', '>= 1.98';

# Used for transcoding - not essential, but commonly used
recommends 'MIME::Base64', 0;
recommends 'JSON::MaybeUTF8', '>= 1.002';
recommends 'Text::CSV', 0;

# Not so common
suggests 'JSON::SL', '>= 1.0.6';
suggests 'XML::LibXML::SAX::ChunkParser', '>= 0.00008';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Deep', '>= 1.124';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
	requires 'Test::Warnings', '>= 0.024';
	requires 'Test::Files', '>= 0.14';
	requires 'Log::Any::Adapter::TAP', '>= 0.003002';
	requires 'Variable::Disposition', '>= 0.004';

	recommends 'Test::HexString', '>= 0.03';
};

on 'develop' => sub {
    requires 'Devel::Cover::Report::Coveralls', '>= 0.11';
    requires 'Devel::Cover';
};
