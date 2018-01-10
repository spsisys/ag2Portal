class AlterViewProductValuedStock < ActiveRecord::Migration
  def change
    execute 'alter view product_valued_stocks as
    select `s`.`store_id` AS `store_id`,`a`.`name` AS `store_name`,`f`.`id` AS `product_family_id`,`f`.`family_code` AS `family_code`,
    `f`.`name` AS `family_name`,`p`.`id` AS `product_id`,`p`.`product_code` AS `product_code`,`p`.`main_description` AS `main_description`,
    `p`.`average_price` AS `average_price`,sum(`s`.`initial`) AS `initial`,sum(`s`.`current`) AS `current`,
    cast(coalesce((sum(`s`.`current`) * `p`.`average_price`),0) as decimal(13,4)) AS `current_value`,
    `a`.`company_id` AS `company_id`,`c`.`name` AS `company_name`
    from (`product_families` `f`
    join (`products` `p`
    join (`stocks` `s`
    join (`stores` `a`
    join `companies` `c` on((`c`.`id` = `a`.`company_id`)))
    on((`a`.`id` = `s`.`store_id`)))
    on((`s`.`product_id` = `p`.`id`)))
    on((`p`.`product_family_id` = `f`.`id`)))
    group by `s`.`store_id`,`f`.`id`,`p`.`id`'
  end
end
