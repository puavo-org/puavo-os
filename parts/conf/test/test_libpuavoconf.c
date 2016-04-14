#include <stdio.h>
#include <stdlib.h>

#include <check.h>

#include "../conf.h"

static puavo_conf_t *conf;

START_TEST(test_empty_db_clear_empty)
{
        ck_assert_int_eq(0, puavo_conf_clear(conf, NULL));
}
END_TEST

START_TEST(test_empty_db_get_from_empty)
{
        char *value;

        ck_assert_int_ne(0, puavo_conf_get(conf, "somekey", &value, NULL));
}
END_TEST

START_TEST(test_empty_db_get_all_from_empty)
{
        struct puavo_conf_list list;

        ck_assert_int_eq(0, puavo_conf_get_all(conf, &list, NULL));
        ck_assert(list.length == 0);
}
END_TEST

START_TEST(test_empty_db_set_same_twice_and_get)
{
        char *value;

        ck_assert_int_eq(0, puavo_conf_set(conf, "somekey", "someval1", NULL));
        ck_assert_int_eq(0, puavo_conf_get(conf, "somekey", &value, NULL));
        ck_assert_str_eq("someval1", value);
        free(value);

        ck_assert_int_eq(0, puavo_conf_set(conf, "somekey", "someval2", NULL));
        ck_assert_int_eq(0, puavo_conf_get(conf, "somekey", &value, NULL));
        ck_assert_str_eq("someval2", value);
        free(value);
}
END_TEST

START_TEST(test_empty_db_set_many_and_get_all)
{
        struct puavo_conf_list list;

        ck_assert_int_eq(0, puavo_conf_set(conf, "somekey1", "someval1", NULL));
        ck_assert_int_eq(0, puavo_conf_set(conf, "somekey2", "someval2", NULL));
        ck_assert_int_eq(0, puavo_conf_set(conf, "somekey3", "someval3", NULL));

        ck_assert_int_eq(0, puavo_conf_get_all(conf, &list, NULL));
        ck_assert(list.length == 3);

        ck_assert_str_eq(list.keys[0], "somekey1");
        ck_assert_str_eq(list.keys[1], "somekey2");
        ck_assert_str_eq(list.keys[2], "somekey3");
        ck_assert_str_eq(list.values[0], "someval1");
        ck_assert_str_eq(list.values[1], "someval2");
        ck_assert_str_eq(list.values[2], "someval3");

        puavo_conf_list_free(&list);
}
END_TEST

START_TEST(test_empty_db_lock_conflict)
{
        puavo_conf_t *conf2;
        ck_assert_int_eq(0, puavo_conf_open(&conf2, NULL));
}
END_TEST

START_TEST(test_type_check)
{
        ck_assert_int_eq(0, puavo_conf_check_type("true",
                                                  PUAVO_CONF_TYPE_BOOL,
                                                  NULL));
        ck_assert_int_eq(0, puavo_conf_check_type("false",
                                                  PUAVO_CONF_TYPE_BOOL,
                                                  NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("yes",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("no",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("TRUE",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("FALSE",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("1",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("0",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(-1, puavo_conf_check_type("",
                                                   PUAVO_CONF_TYPE_BOOL,
                                                   NULL));
        ck_assert_int_eq(0, puavo_conf_check_type("true",
                                                  PUAVO_CONF_TYPE_ANY,
                                                  NULL));
        ck_assert_int_eq(0, puavo_conf_check_type("",
                                                  PUAVO_CONF_TYPE_ANY,
                                                  NULL));
}
END_TEST

static void setup_empty_db()
{
        setenv("PUAVO_CONF_DB_FILEPATH", "test.db", 1);
        ck_assert_int_eq(0, puavo_conf_open(&conf, NULL));
        ck_assert_ptr_ne(conf, NULL);
        ck_assert_int_eq(0, puavo_conf_clear(conf, NULL));
}

static void teardown_empty_db()
{
        puavo_conf_close(conf, NULL);
}

static Suite *libpuavoconf_suite_create(void)
{
        Suite *suite          = suite_create("Puavo Conf");
        TCase *tcase_empty_db = tcase_create("Empty database");

        tcase_add_checked_fixture(tcase_empty_db, setup_empty_db,
                                  teardown_empty_db);

        tcase_add_test(tcase_empty_db, test_empty_db_clear_empty);
        tcase_add_test(tcase_empty_db, test_empty_db_get_from_empty);
        tcase_add_test(tcase_empty_db, test_empty_db_get_all_from_empty);
        tcase_add_test(tcase_empty_db, test_empty_db_set_same_twice_and_get);
        tcase_add_test(tcase_empty_db, test_empty_db_set_many_and_get_all);
        tcase_add_test(tcase_empty_db, test_empty_db_lock_conflict);
        tcase_add_test(tcase_empty_db, test_type_check);

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
