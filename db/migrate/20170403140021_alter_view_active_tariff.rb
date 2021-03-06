class AlterViewActiveTariff < ActiveRecord::Migration
  def change
    execute 'alter view active_tariffs as
    SELECT `tariffs`.`id` AS `tariff_id`, `tariffs`.`billable_item_id`, `billable_items`.`project_id`, `projects`.`project_code`, `tariffs`.`tariff_type_id`,
    `tariff_types`.`code` AS `tariff_type_code`, `billable_items`.`billable_concept_id`, `billable_concepts`.`code` AS `billable_concept_code`, `tariffs`.`caliber_id`,
    `calibers`.`caliber`, `tariffs`.`billing_frequency_id`, `billing_frequencies`.`name` AS `billing_frequency_name`, `tariffs`.`starting_at`,
    COALESCE (`tariffs`.`fixed_fee`, 0) AS `fixed_fee`, COALESCE (`tariffs`.`variable_fee`, 0) AS `variable_fee`, COALESCE (`tariffs`.`percentage_fee`, 0) AS `percentage_fee`,
    `tariffs`.`percentage_applicable_formula`, `tariffs`.`block1_limit`, `tariffs`.`block2_limit`, `tariffs`.`block3_limit`, `tariffs`.`block4_limit`, `tariffs`.`block5_limit`,
    `tariffs`.`block6_limit`, `tariffs`.`block7_limit`, `tariffs`.`block8_limit`, COALESCE (`tariffs`.`block1_fee`, 0) AS `block1_fee`, COALESCE (`tariffs`.`block2_fee`, 0) AS `block2_fee`,
    COALESCE (`tariffs`.`block3_fee`, 0) AS `block3_fee`, COALESCE (`tariffs`.`block4_fee`, 0) AS `block4_fee`, COALESCE (`tariffs`.`block5_fee`, 0) AS `block5_fee`,
    COALESCE (`tariffs`.`block6_fee`, 0) AS `block6_fee`, COALESCE (`tariffs`.`block7_fee`, 0) AS `block7_fee`, COALESCE (`tariffs`.`block8_fee`, 0) AS `block8_fee`,
    COALESCE (`tariffs`.`discount_pct_f`, 0) AS `discount_pct_f`, COALESCE (`tariffs`.`discount_pct_v`, 0) AS `discount_pct_v`, COALESCE (`tariffs`.`discount_pct_p`, 0) AS `discount_pct_p`,
    COALESCE (`tariffs`.`discount_pct_b`, 0) AS `discount_pct_b`, `tariffs`.`tax_type_f_id`, `tariffs`.`tax_type_v_id`, `tariffs`.`tax_type_p_id`, `tariffs`.`tax_type_b_id`,
    COALESCE (`tariffs`.`percentage_fixed_fee`, 0) AS `percentage_fixed_fee`
    FROM `tariffs`
    INNER JOIN `tariff_types` ON `tariffs`.`tariff_type_id` = `tariff_types`.`id`
    INNER JOIN `calibers` ON `tariffs`.`caliber_id` = `calibers`.`id`
    INNER JOIN `billing_frequencies` ON `tariffs`.`billing_frequency_id` = `billing_frequencies`.`id`
    INNER JOIN ( `billable_items` INNER JOIN `billable_concepts` ON `billable_items`.`billable_concept_id` = `billable_concepts`.`id` INNER JOIN `projects` ON `billable_items`.`project_id` = `projects`.`id` ) ON `tariffs`.`billable_item_id` = `billable_items`.`id`
    WHERE `tariffs`.`ending_at` IS NULL'
  end
end
