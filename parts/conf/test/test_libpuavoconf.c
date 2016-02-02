#include <stdio.h>
#include <stdlib.h>

#include <check.h>

#include "../conf.h"

static puavo_conf_t *conf;

START_TEST(test_empty_db_clear)
{
	ck_assert_int_eq(0, puavo_conf_clear_db(conf));
}
END_TEST

START_TEST(test_empty_db_get)
{
	char *value;

	ck_assert_int_eq(-PUAVO_CONF_ERR_DB,
			 puavo_conf_get(conf, "somekey", &value));
}
END_TEST

START_TEST(test_empty_db_list)
{
	struct puavo_conf_param *params;
	size_t len;

	ck_assert_int_eq(0, puavo_conf_list(conf, &params, &len));
	ck_assert(len == 0);
}
END_TEST

START_TEST(test_empty_db_set_same_twice_and_get)
{
	char *value;

	ck_assert_int_eq(0, puavo_conf_set(conf, "somekey", "someval1"));
	ck_assert_int_eq(0, puavo_conf_get(conf, "somekey", &value));
	ck_assert_str_eq("someval1", value);
	free(value);

	ck_assert_int_eq(0, puavo_conf_set(conf, "somekey", "someval2"));
	ck_assert_int_eq(0, puavo_conf_get(conf, "somekey", &value));
	ck_assert_str_eq("someval2", value);
	free(value);
}
END_TEST

START_TEST(test_empty_db_set_many_and_list)
{
	struct puavo_conf_param *params;
	size_t len;

	ck_assert_int_eq(0, puavo_conf_set(conf, "somekey1", "someval1"));
	ck_assert_int_eq(0, puavo_conf_set(conf, "somekey2", "someval2"));
	ck_assert_int_eq(0, puavo_conf_set(conf, "somekey3", "someval3"));

	ck_assert_int_eq(0, puavo_conf_list(conf, &params, &len));
	ck_assert(len == 3);

	ck_assert_str_eq(params[0].key, "somekey1");
	ck_assert_str_eq(params[0].val, "someval1");
	ck_assert_str_eq(params[1].key, "somekey2");
	ck_assert_str_eq(params[1].val, "someval2");
	ck_assert_str_eq(params[2].key, "somekey3");
	ck_assert_str_eq(params[2].val, "someval3");

	free(params[0].key);
	free(params[0].val);
	free(params[1].key);
	free(params[1].val);
	free(params[2].key);
	free(params[2].val);
	free(params);
}
END_TEST

static void setup_empty_db()
{
	ck_assert_int_eq(0, puavo_conf_init(&conf));
	ck_assert_ptr_ne(conf, NULL);
	ck_assert_int_eq(0, puavo_conf_open_db(conf, "test.db"));
	ck_assert_int_eq(0, puavo_conf_clear_db(conf));
}

static void teardown_empty_db()
{
	puavo_conf_free(conf);
}

static Suite *libpuavoconf_suite_create(void)
{
	Suite *suite          = suite_create("Puavo Conf");
	TCase *tcase_empty_db = tcase_create("Empty database");

	tcase_add_checked_fixture(tcase_empty_db, setup_empty_db,
				  teardown_empty_db);

	tcase_add_test(tcase_empty_db, test_empty_db_clear);
	tcase_add_test(tcase_empty_db, test_empty_db_get);
	tcase_add_test(tcase_empty_db, test_empty_db_list);
	tcase_add_test(tcase_empty_db, test_empty_db_set_same_twice_and_get);
	tcase_add_test(tcase_empty_db, test_empty_db_set_many_and_list);

	suite_add_tcase(suite, tcase_empty_db);

	return suite;
}

int main(void)
{
	int      fail_count;
	Suite   *suite       = libpuavoconf_suite_create();
	SRunner *srunner     = srunner_create(suite);

	srunner_run_all(srunner, CK_NORMAL);
	fail_count = srunner_ntests_failed(srunner);
	srunner_free(srunner);

	return fail_count ? EXIT_FAILURE : EXIT_SUCCESS;
}
