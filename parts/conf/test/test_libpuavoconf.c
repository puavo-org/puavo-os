#include <stdio.h>
#include <stdlib.h>

#include <check.h>

#include "../conf.h"

START_TEST(test_puavo_conf_get_empty_db)
{
	puavo_conf_t *conf;
	char *value;
	struct puavo_conf_param *params;
	size_t len;

	ck_assert_int_eq(0, puavo_conf_init(&conf));
	ck_assert_int_eq(0, puavo_conf_open_db(conf, "test.db"));

	ck_assert_int_eq(0, puavo_conf_clear_db(conf));
	ck_assert_int_eq(0, puavo_conf_list(conf, &params, &len));
	ck_assert(len == 0);
	ck_assert_int_eq(-PUAVO_CONF_ERR_DB,
			 puavo_conf_get(conf, "somekey", &value));

	ck_assert_int_eq(0, puavo_conf_close_db(conf));
	puavo_conf_free(conf);
}
END_TEST

static Suite *puavo_conf_suite(void)
{
	Suite *s;
	TCase *tc_empty_db;

	s = suite_create("Puavo Conf");

	tc_empty_db = tcase_create("Empty database");

	tcase_add_test(tc_empty_db, test_puavo_conf_get_empty_db);

	suite_add_tcase(s, tc_empty_db);

	return s;
}

int main(void)
{
	int number_failed;
	Suite *s;
	SRunner *sr;

	s = puavo_conf_suite();
	sr = srunner_create(s);

	srunner_run_all(sr, CK_NORMAL);
	number_failed = srunner_ntests_failed(sr);
	srunner_free(sr);
	return (number_failed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
