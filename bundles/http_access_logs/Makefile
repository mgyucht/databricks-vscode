fmt:
	black lib test
	autoflake -ri lib test

lint:
	pycodestyle lib test
	autoflake --check-diff --quiet --recursive lib test
