#include <stdio.h>
#include <stdlib.h>

#include <check.h>

#include "../conf.h"

START_TEST(test_puavo_conf_init)
{
	puavo_conf_t *conf;

	puavo_conf_init(&conf);
	ck_assert_ptr_ne(conf, NULL);
	puavo_conf_free(conf);
}
END_TEST

static Suite *puavo_conf_suite(void)
{
	Suite *s;
	TCase *tc_core;

	s = suite_create("Puavo Conf");

	tc_core = tcase_create("Core");

	tcase_add_test(tc_core, test_puavo_conf_init);
	suite_add_tcase(s, tc_core);

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
