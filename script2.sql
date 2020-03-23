use zomatodb;

insert into organization values (1,'Zomato');
select * from user ;
insert into user values ('admin','zadmin@gmail.com','zomatoAdmin','password4','zomato');
insert into user values ('deshmukh','tanu1@gmail.com','tdeshmukh','password1','tanushree');
insert into user values ('mehta','priya1@gmail.com','pmehta','password2','priya');
insert into user values ('boralkar','aish@gmail.com','aboralkar','password3','aishwarya');



insert into useraccount values (1,'password1','tdeshmukh',1);
insert into useraccount values (2,'password2','pmehta',1);
insert into useraccount values (3,'password3','aboralkar',1);
insert into useraccount values (4,'password4','zomatoAdmin',1);

insert into restaurant values (1,'Marriot','fivestar',1);
insert into restaurant values (2,'Taj','fourstar',1);

insert into foodcategory values(1,'Indian','veg');
insert into foodcategory values(2,'Chinese','nonveg');

insert into fooditem values (1,'dosa','20',2,1);
insert into fooditem values (2,'noodles','30',1,2);

insert into address values (1,10,'Saint Germain ','Boston','MA',02115);
insert into address values (2,20,'Fenway','SanDiego','California',02110);

select * from customerorder;
insert into customerorder values(1,'2018-10-11',1,1);
insert into customerorder values(2,'2018-11-12',2,1);
insert into customerorder values(3,'2018-10-13',1,2);
insert into customerorder values(4,'2018-11-14',2,2);

insert into paymentmethod values (1,'credit card',1);
insert into paymentmethod values (2,'cash',2);

insert into deliverydetails values (1,'deliveryboy1','USA','2018-10-10',1);
insert into deliverydetails values (2,'deliveryboy2','USA','2018-10-11',2);

insert into delivery values (1,'zomato',1);


select * from restaurant_has_foodcategory ;
insert into bill value (1,1,1,1);
insert into bill value (2,2,2,1);

insert into customerorder_has_fooditem values (1,1);
insert into customerorder_has_fooditem values (2,2);

insert into restaurant_has_foodcategory values (1,1);
insert into restaurant_has_foodcategory values (2,2);
insert into restaurant_has_foodcategory values (1,2);
insert into restaurant_has_foodcategory values (2,1);

-- user privileges--
create user zomatoAdmin identified by 'password4';
revoke all privileges,grant option from zomatoAdmin;
grant all on zomatodb.*to zomatoAdmin;
create user tdeshmukh identified by 'password1';
revoke all privileges,grant option from tdeshmukh;
grant select on zomatodb.bill to tdeshmukh;
grant select on zomatodb.deliverydetails to tdeshmukh;
grant select on zomatodb.foodcategory to tdeshmukh;
grant select on zomatodb.fooditem to tdeshmukh;
grant select on zomatodb.restaurant to tdeshmukh;
grant update ,delete on zomatodb.customerorder to tdeshmukh;
grant update ,delete on zomatodb.paymentmethod to tdeshmukh;
grant update ,delete on zomatodb.address to tdeshmukh;
grant create,update,delete on zomatodb.useraccount to tdeshmukh;

-- view 1 Customer Order Details--
create view customer_order
as
select cfi.CustomerOrderId,u.UserName,r.RestaurantId,fc.Categoryname,fi.FoodItemName,fi.FoodItemPrice
from useraccount u inner join organization o on u.OrgId = o.OrgId
inner join restaurant r on o.OrgId = r.OrgId 
inner join restaurant_has_foodcategory rfc on r.RestaurantId = rfc.RestaurantId
inner join foodcategory fc on rfc.CategoryId = fc.CategoryId
inner join foodItem fi on fc.CategoryId = fi.CategoryId
inner join customerorder_has_fooditem cfi on fi.FoodItemId = cfi.FoodItemId
;

select * from customer_order;

-- view 2 Customer Bill Details--

create view customer_bill
as 
select distinct b.BillId, r.RestaurantId,cfi.CustomerOrderId, r.RestaurantName, fi.Quantity, fi.FoodItemPrice, fi.Quantity*fi.FoodItemPrice AS Total from useraccount u
inner join restaurant r on u.OrgId = r.OrgId 
inner join restaurant_has_foodcategory rfc on r.RestaurantId = rfc.RestaurantId
inner join foodcategory fc on rfc.CategoryId = fc.CategoryId
inner join foodItem fi on fc.CategoryId = fi.CategoryId
inner join customerorder_has_fooditem cfi on fi.FoodItemId = cfi.FoodItemId
inner join bill b on cfi.CustomerOrderId = b.CustomerOrder_OrderId
order by RestaurantId;

select * from customer_bill;

-- Procedure 1 - Discount on food items for Restaurant "Marriot"--
delimiter &&
create procedure Marriotdiscount_20percent()
begin

select r.RestaurantName,fi.FoodItemName,(fi.FoodItemPrice-(0.2*fi.FoodItemPrice)) as 'Discounted Price of food item' from fooditem fi inner join foodcategory fc
on fi.CategoryId=fc.CategoryId inner join restaurant_has_foodcategory rfc
on fc.CategoryId=rfc.CategoryId inner join restaurant r on r.RestaurantId = rfc.RestaurantId
where r.RestaurantId = 1;
end;
&& 

call Marriotdiscount_20percent();


-- Procedure 2 - Delivery Details based on DeliveryDetailId --

delimiter //
create procedure sp_deliveryDetailss1 (in num int) 
begin
select u.UserId,u.UserName,r.RestaurantId,r.RestaurantName,co.CustomerOrderId, fi.FoodItemName, fi.FoodItemPrice, fi.FoodItemPrice*fi.Quantity AS Total,a.AptNo, a.Street, a.City,
b.BillId, dd.DeliveryBoyName from user us inner join useraccount u on us.UserName = u.UserName
inner join restaurant r on u.OrgId = r.OrgId 
inner join restaurant_has_foodcategory rfc on r.RestaurantId = rfc.RestaurantId
inner join foodcategory fc on rfc.CategoryId = fc.CategoryId
inner join foodItem fi on fc.CategoryId = fi.CategoryId
inner join customerorder_has_fooditem cfi on fi.FoodItemId = cfi.FoodItemId
inner join customerorder co on co.CustomerOrderId = cfi.CustomerOrderId
inner join address a on co.AddressId = a.AddressId
inner join bill b on b.CustomerOrder_OrderId = co.CustomerOrderId
inner join delivery d on d.DeliveryId = b.DeliveryId
inner join deliverydetails dd on dd.DeliveryDetailId = d.DeliveryDetailsId
where dd.DeliveryDetailId = num
order by RestaurantId;
end;
//

call sp_deliveryDetailss1(1);

-- Analysis 1 : FoodCategory generating highest revenue--


SELECT CategoryName,(select max((o.FoodItemPrice*o.Quantity)) from fooditem o 
where o.CategoryId=fc.CategoryId) as 'Total Revenue'
,CategoryId
FROM foodcategory fc
where (select max((o.FoodItemPrice*o.Quantity)) from fooditem o 
where o.CategoryId=fc.CategoryId)
order by (select max((o.FoodItemPrice*o.Quantity)) from fooditem o 
where o.CategoryId=fc.CategoryId) desc
Limit 1;

-- Analysis 2: Address from where customers order the most--
select AddressId,
(select count(*) from customerorder a where a.AddressId = c.AddressId)>=0 as 'Address count'
from address c #where (select count(*) from customerorder a where a.AddressId = c.AddressId)>=0
group by AddressId;



-- Cursor--
DELIMITER $$

CREATE PROCEDURE build_custo_list (INOUT customer_list varchar(3000))
BEGIN
 
 DECLARE v_finished INTEGER DEFAULT 0;
        DECLARE v_customer varchar(50) DEFAULT "";
 
 DEClARE customer_cursor CURSOR FOR 
 SELECT UserName FROM useraccount;
 
 DECLARE CONTINUE HANDLER 
        FOR NOT FOUND SET v_finished = 1;
 
 OPEN customer_cursor;
 
 get_Last_Name: LOOP
 
 FETCH customer_cursor INTO v_customer;
 
 IF v_finished = 1 THEN 
 LEAVE get_Last_Name;
 END IF;
 
 SET customer_list = CONCAT(v_customer,";",customer_list);
 
 END LOOP get_Last_Name;
 
 CLOSE customer_cursor;

END$$
 
DELIMITER ;

SET @customer_list = "";
CALL build_custo_list(@customer_list);
SELECT @customer_list;

-- Trigger--
create table TriggerGeneratedOnUser(
triggerId int primary key , UserName varchar(25),  Date timestamp );

desc TriggerGeneratedOnUser;
select * from TriggerGeneratedOnUser;

DELIMITER //
create trigger TriggerGenereatedOnUser2
after insert
on user
FOR EACH ROW

Begin

insert into TriggerGeneratedOnUser
values (1,user(),now());
END;
//

insert into user values ('patil','prith@gmail.com','ppatil','password3','prithviraj');
select * from TriggerGeneratedOnUser;

-- Transaction--
start transaction;
savepoint trans;
update user set LName="pops" where UserName='pmehta';

Rollback to trans;
update user set LName="mehta" where UserName='pmehta';
Commit;
select * from user;


-- UDF--
DELIMITER $$
 
CREATE FUNCTION PriceLevel(p_price int) RETURNS VARCHAR(10)
    DETERMINISTIC
BEGIN
    DECLARE lvl varchar(10);
 
    IF p_price > 25 THEN
 SET lvl = 'High';
    ELSEIF (p_price <= 25) THEN
        SET lvl = 'Low';
    
    END IF;
 
 RETURN (lvl);
END $$
DELIMITER ;

SELECT FoodItemName,PriceLevel(FoodItemPrice) from fooditem ORDER BY FoodItemName;
