import unittest

from script.create_off_food_db import COUNTRY_CONFIG, extract_product_name, has_country_tag


class NewOffCountryConfigTests(unittest.TestCase):
    def test_country_tags_match_products_sold_in_each_region(self):
        cases = {
            "nl": ("en:netherlands",),
            "es": ("en:spain",),
            "au": ("en:australia",),
        }
        for country, matching_tags in cases.items():
            with self.subTest(country=country):
                configured_tags = COUNTRY_CONFIG[country]["country_tags"]
                self.assertTrue(has_country_tag(matching_tags, configured_tags))
                self.assertFalse(has_country_tag(("en:france",), configured_tags))

    def test_country_language_preferences_have_english_fallback(self):
        expected = {"nl": ("nl", "en"), "es": ("es", "en"), "au": ("en",)}
        for country, languages in expected.items():
            with self.subTest(country=country):
                self.assertEqual(COUNTRY_CONFIG[country]["preferred_languages"], languages)

    def test_product_names_prefer_region_language_then_english(self):
        product_names = {"nl": "Havermelk", "es": "Leche de avena", "en": "Oat drink"}
        for country, preferred in (("nl", "Havermelk"), ("es", "Leche de avena")):
            with self.subTest(country=country, preference="regional"):
                self.assertEqual(
                    extract_product_name(product_names, COUNTRY_CONFIG[country]["preferred_languages"]),
                    preferred,
                )
            with self.subTest(country=country, preference="english fallback"):
                self.assertEqual(
                    extract_product_name({"en": "Oat drink"}, COUNTRY_CONFIG[country]["preferred_languages"]),
                    "Oat drink",
                )
        self.assertEqual(
            extract_product_name(product_names, COUNTRY_CONFIG["au"]["preferred_languages"]),
            "Oat drink",
        )


if __name__ == "__main__":
    unittest.main()
