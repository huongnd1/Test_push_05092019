--Call thu tuc cua package


variable OP_RESULT refcursor;
variable OP_ERR VARCHAR2(200);
variable  OP_DESC VARCHAR2(200);
exec OJB_PCK_ACCOUNT.pr_getListAccountByCif('900490779',:OP_ERR,:OP_DESC,:OP_RESULT);
print OP_RESULT;

-----------------------------------
create or replace
PROCEDURE proc_kk_CDC_TBVP_sum(
    kkPeriodId IN NUMBER,
    groupId    IN NUMBER,
    groupCode  IN NVARCHAR2,
    groupName  IN NVARCHAR2,
    groupPath  IN NVARCHAR2)
AS
  v_error NVARCHAR2 (1000);
  v_count  NUMBER :=0;
  v_count1 NUMBER :=0;
  --    lay danh sach hang hoa da kiem ke
  CURSOR c_mer
  IS
    SELECT c.group_id,
      c.mer_id,
      d.code AS mer_code,
      d.name AS mer_name,
      d.is_device,
      e.unit_id,
      e.name            AS unit_name,
      SUM(c.count_good) AS KK_COUNT_GOOD,
      SUM(c.count_bad)  AS KK_COUNT_BAD,
      c.CAT_EMPLOYEE_ID,
      c.EMPLOYEE_CODE,
      c.EMPLOYEE_NAME,
      c.EMAIL,
      c.ASSET_TYPE,
      CASE
          (SELECT COUNT(1)
          FROM CONFIRM_FINISH_INVENTORY a
          WHERE a.group_id   =c.group_id
          AND a.kk_period_id = c.kk_period_id
          AND a.status       =1
          )
      WHEN 0
      THEN 1
      ELSE 2
    END IS_KK
  FROM mer_entity_kiemke_ccdc_tbvp c
  JOIN cat_merchandise d
  ON (c.mer_id    = d.merchandise_id
  AND d.is_active =1)
  LEFT JOIN cat_unit e
  ON d.unit_id         =e.unit_id
  WHERE c.kk_period_id = kkPeriodId
  AND c.group_id       = groupId
  GROUP BY c.group_id,
    d.code,
    d.name,
    e.unit_id,
    e.name,
    d.is_device,
    c.mer_id,
    c.kk_period_id,
    c.ASSET_TYPE,
    c.CAT_EMPLOYEE_ID,
    c.EMPLOYEE_CODE,
    c.EMPLOYEE_NAME,
    c.EMAIL;
  --    lay danh sach hang hoa da kiem ke da xac nhan
  CURSOR c_mer_sys
  IS
    SELECT a.GROUP_ID,
      a.MER_ID,
      b.code AS mer_code,
      b.name AS mer_name,
      b.is_device,
      d.unit_id,
      d.name                            AS unit_name,
      ( SUM(a.COUNT))                   AS SYS_COUNT,
      (SUM(a.COUNT) * a.ORIGINAL_PRICE) AS SYS_PRICE,
      a.CAT_EMPLOYEE_ID,
      2             AS IS_KK,
      a.ENTITY_TYPE AS ASSET_TYPE
    FROM mer_entity_sys_ccdc_tbvp a
    JOIN cat_merchandise b
    ON (a.mer_id    = b.merchandise_id
    AND b.is_active =1)
    LEFT JOIN cat_unit d
    ON b.unit_id       =d.unit_id
    WHERE a.status_id IN (1,2,3)
    AND a.is_temp      =0
    AND a.kk_period_id = kkPeriodId
    AND a.group_id     = groupId
    GROUP BY a.GROUP_ID,
      a.MER_ID,
      b.code ,
      b.name ,
      b.is_device,
      d.unit_id,
      d.name ,
      a.COUNT,
      a.ORIGINAL_PRICE,
      a.CAT_EMPLOYEE_ID,
      a.ENTITY_TYPE;
BEGIN
  -- Xoa du lieu cua don vi
  DELETE RP_KK_CDC_TBVP_SUM a
  WHERE a.GROUP_ID = groupId
  AND a.PERIOD_ID  = kkPeriodId;
  --  Inser du lieu theo tung don vi
  --Voi hang hoa kiem ke
  FOR cur IN c_mer
  LOOP
    v_count := v_count + 1;
    INSERT
    INTO RP_KK_CDC_TBVP_SUM
      (
        RP_KK_CDC_TBVP_SUM_ID,
        GROUP_ID,
        GROUP_CODE,
        GROUP_NAME,
        GROUP_PATH,
        MER_ID,
        MER_CODE,
        MER_NAME,
        IS_DEVICE,
        UNIT_ID,
        UNIT_NAME,
        KK_COUNT_GOOD,
        KK_COUNT_BAD,
        SYS_COUNT,
        SYS_PRICE,
        CLOSED_SYS_COUNT,
        CLOSED_SYS_PRICE,
        CREATED_DATE,
        NOTE,
        PERIOD_ID,
        IS_KK,
        EMPLOYEE_ID,
        EMPLOYEE_CODE,
        EMPLOYEE_NAME,
        EMPLOYEE_PHONE,
        EMPLOYEE_EMAIL,
        ASSET_TYPE
      )
      VALUES
      (
        RP_KK_CDC_TBVP_SUM_SEQ.nextval,
        groupId,
        groupCode,
        groupName,
        groupPath,
        cur.mer_id,
        cur.mer_code,
        cur.mer_name,
        cur.is_device,
        cur.unit_id,
        cur.unit_name,
        cur.KK_COUNT_GOOD,
        cur.KK_COUNT_BAD,
        NULL,
        NULL,
        NULL,
        NULL,
        sysdate,
        NULL,
        kkPeriodId,
        cur.IS_KK,
        cur.CAT_EMPLOYEE_ID,
        cur.EMPLOYEE_CODE,
        cur.EMPLOYEE_NAME,
        NULL,
        cur.EMAIL,
        cur.ASSET_TYPE
      );
    IF (v_count = 1000) THEN
      COMMIT;
      v_count := 0;
    END IF;
  END LOOP;
  COMMIT;
  --Voi hang hoa da hoan thanh KK
  FOR cur_sys IN c_mer_sys
  LOOP
    v_count1                                                  := v_count1 + 1;
    MERGE INTO RP_KK_CDC_TBVP_SUM d USING dual ON ( d.mer_code = cur_sys.mer_code AND d.GROUP_ID = cur_sys.GROUP_ID AND d.period_id = kkPeriodId)
  WHEN MATCHED THEN
    UPDATE
    SET d.SYS_COUNT = cur_sys.SYS_COUNT,
      d.SYS_PRICE   = cur_sys.SYS_PRICE WHEN NOT MATCHED THEN
    INSERT
      (
        RP_KK_CDC_TBVP_SUM_ID,
        GROUP_ID,
        GROUP_CODE,
        GROUP_NAME,
        GROUP_PATH,
        MER_ID,
        MER_CODE,
        MER_NAME,
        IS_DEVICE,
        UNIT_ID,
        UNIT_NAME,
        KK_COUNT_GOOD,
        KK_COUNT_BAD,
        SYS_COUNT,
        SYS_PRICE,
        CLOSED_SYS_COUNT,
        CLOSED_SYS_PRICE,
        CREATED_DATE,
        NOTE,
        PERIOD_ID,
        IS_KK,
        EMPLOYEE_ID,
        EMPLOYEE_CODE,
        EMPLOYEE_NAME,
        EMPLOYEE_PHONE,
        EMPLOYEE_EMAIL,
        ASSET_TYPE
      )
      VALUES
      (
        RP_KK_CDC_TBVP_SUM_SEQ.nextval,
        groupId,
        groupCode,
        groupName,
        groupPath,
        cur_sys.mer_id,
        cur_sys.mer_code,
        cur_sys.mer_name,
        cur_sys.is_device,
        cur_sys.unit_id,
        cur_sys.unit_name,
        NULL,
        NULL,
        cur_sys.SYS_COUNT,
        cur_sys.SYS_PRICE,
        NULL,
        NULL,
        sysdate,
        NULL,
        kkPeriodId,
        cur_sys.IS_KK,
        cur_sys.CAT_EMPLOYEE_ID,
        NULL,
        NULL,
        NULL,
        NULL,
        cur_sys.ASSET_TYPE
      );
    IF (v_count1 = 1000) THEN
      COMMIT;
      v_count1 := 0;
    END IF;
  END LOOP;
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  ROLLBACK;
  v_error := SQLERRM;
  INSERT
  INTO error
    (
      err,
      sys_time,
      action
    )
    VALUES
    (
      v_error,
      SYSDATE,
      ''RP_KK_CDC_TBVP_SUM''
    );
END;

--------------------------------------------------------------



create or replace
FUNCTION F_GET_CONTRACT_CODE (p_construction_id in number) RETURN NCLOB AS
return_value NCLOB;
BEGIN
  for c_code in
  (
    select c.code from constr_constructions a 
    join cnt_constr_refer b on (a.construct_id = b.construct_id and b.status is null)
    join cnt_contract c on (b.contract_id = c.contract_id and c.is_active =1)
    where a.is_active =1 and a.construct_id = p_construction_id
  )
  loop
    return_value := return_value || c_code.code || ';';
  end loop;
  return_value := substr(return_value, 1, length(return_value) - 1);
  return return_value;
END F_GET_CONTRACT_CODE;

-------------------------------------------------------------


create or replace FUNCTION get_data(id in number) RETURN NCLOB
as
return_value NCLOB;
begin
for c in(
select a.MER_ENTITY_ID,a.MER_NAME, a.ADDRESS, a.EMPLOYEE_NAME, b.ASSET_TYPE_NAME, 
a.CREATED_DATE
from MER_ENTITY a
left join ASSET_TYPE b on a.ASSET_TYPE_ID = b.ASSET_TYPE_ID and b.IS_ACTIVE=1
LEFT join SYS_GROUP c on a.GROUP_ID = c.GROUP_ID and c.IS_ACTIVE=1
where a.IS_ACTIVE=1
)
loop
if (c.MER_ENTITY_ID >id) then
return_value := return_value || c.MER_NAME;
end if;
end loop;
return return_value;
end;
------------------------------------------------------------------------------------------------

create or replace PROCEDURE pro_student(email in VARCHAR2, mark in number) as
begin
for c in(
select a.MER_ENTITY_ID,a.MER_NAME, a.ADDRESS, a.EMPLOYEE_NAME, b.ASSET_TYPE_NAME, 
a.CREATED_DATE
from MER_ENTITY a
left join ASSET_TYPE b on a.ASSET_TYPE_ID = b.ASSET_TYPE_ID and b.IS_ACTIVE=1
LEFT join SYS_GROUP c on a.GROUP_ID = c.GROUP_ID and c.IS_ACTIVE=1
where a.IS_ACTIVE=1)
loop
  Insert into tblstudent (ID,NAME,DOB,ADDRESS,PHONE,EMAIL,MARK) values (c.MER_ENTITY_ID,c.MER_NAME,c.CREATED_DATE,c.ADDRESS,'1222333',email,mark);
  COMMIT;
end loop;
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
end;

------------------------------------------------------------------------------------------------

create or replace procedure pro_insert(idTbl in nvarchar2, nameTbl in nvarchar2, dobTbl in Date, addre in nvarchar2, phonetbl in nvarchar2, emailtbl in nvarchar2,
 marktbl in number) as
begin
INSERT INTO TBLSTUDENT VALUES(idTbl,nameTbl,dobTbl,addre,phonetbl,emailtbl,marktbl);
commit;
EXCEPTION when others then
rollback;
end;

------------------------------------------------------------------------------------------------

create or replace PROCEDURE pro_delete(idstudent in number) as
begin
DELETE FROM TBLSTUDENT a WHERE a.id = idstudent;
commit;
Exception when others then
rollback;
end;
------------------------------------------