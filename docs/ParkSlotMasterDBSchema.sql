-------------------------------------------------------------------------------------------------------------------------------------

Create trigger trg_reservation_cleanup ON dbo.Reservation_Details 
Instead of delete
AS
BEGIN
    
Insert into dbo.Vehicle_Details(         -- storing vehicle history
    ReservationId, LicenseNo, SlotNumber
)
Select 
    deleted.ReservationId,
    deleted.LicenseNo,
    deleted.SlotNumber
from deleted 


Insert into dbo.User_History (     --stroing user history
    HistoryId,UserCNIC
)
Select 
     dbo.Vehicle_Details.HistoryId,
	 deleted.UserCNIC
from deleted
left join dbo.Vehicle_Details On dbo.Vehicle_Details.ReservationId = deleted.ReservationId;

Insert into dbo.History_Records (     --stroing time history
     HistoryId,ArrivalTime,DepartureTime 
)
Select 
     dbo.Vehicle_Details.HistoryId,
	 dbo.Reservation_TimeInterval_Record.ArrivalTime,
	 dbo.Reservation_TimeInterval_Record.DepartureTime
from deleted 
left join dbo.Reservation_TimeInterval_Record On dbo.Reservation_TimeInterval_Record.ReservationId = deleted.ReservationId
left join dbo.Vehicle_Details On deleted.ReservationId = dbo.Vehicle_Details.ReservationId;

Insert into dbo.Charges_History(  -- stroing charges history
   HistoryId,ParkingFee,Fine
)
Select 
dbo.Vehicle_Details.HistoryId,
dbo.Reservations_Charges.ParkingFee,
dbo.Reservations_Charges.Fine
from deleted
left join dbo.Reservations_Charges On deleted.ReservationId = dbo.Reservations_Charges.ReservationId 
left join dbo.Vehicle_Details On dbo.Vehicle_Details.ReservationId = deleted.ReservationId;


Update dbo.ParkingSlots set dbo.ParkingSlots.Status = 'Available'       --updating the status to available after the slot is free
from dbo.ParkingSlots join deleted 
ON dbo.ParkingSlots.SlotNumber = deleted.SlotNumber;

Delete dbo.Reservations_Charges        -- delete charges from current reservations
from dbo.Reservations_Charges   
join deleted ON dbo.Reservations_Charges .ReservationId = deleted.ReservationId;

Delete dbo.Reservation_TimeInterval_Record     --delete timeinterval from current reservations
from dbo.Reservation_TimeInterval_Record
join deleted ON deleted.ReservationId = dbo.Reservation_TimeInterval_Record.ReservationId;

Delete dbo.Reservation_Details  -- delete details from current reservations
from dbo.Reservation_Details 
join deleted ON dbo.Reservation_Details.ReservationId = deleted.ReservationId;

Delete dbo.Vehicles   -- delete that vehicle details from current vehicles
from dbo.Vehicles 
join deleted ON dbo.Vehicles .LicenseNo = deleted.LicenseNo
where not exists 
(
    Select 1 from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = dbo.Vehicles.LicenseNo
);

Delete dbo.Users    -- delete user detials from current users
from dbo.Users 
join deleted ON dbo.Users.UserCNIC = deleted.UserCNIC
where not exists 
(
    Select 1 from dbo.Reservation_Details where dbo.Reservation_Details.UserCNIC = dbo.Users.UserCNIC
);

END;
GO

Delete from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = 'LEE_678'

drop trigger trg_reservation_cleanup

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go
Create Procedure CalculateParkingFee
    @ArrivalDate Datetime,
    @DepartureDate Datetime,
	@ReservationID int 
As Begin
   
    Declare @ParkingFeeRate Decimal(10,2) = 0.5;
    Declare @TotalMinutes Int;
    Declare @ParkingFee Decimal(10,2);

    If @ReservationId is not null

    Begin   -- calculate parking fee as per minute = 0.5 ruppess
       
        Set @TotalMinutes = DATEDIFF(MINUTE, @ArrivalDate, @DepartureDate);

        Set @ParkingFee = @TotalMinutes * @ParkingFeeRate;

        Insert into dbo.Reservations_Charges (ReservationId, ParkingFee, Fine)
        values (@ReservationId, @ParkingFee, NULL);    -- inserting null at fine since cant caluclate it now
    
	end

    else

    begin
        Print 'Reservation not found for given arrival and departure times.';
    end

end;

Go
drop procedure CalculateParkingFee

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go

Create trigger trg_CalculateParkingFee
ON dbo.Reservation_TimeInterval_Record
After Insert
As
Begin
    Declare @ReservationId INT;
    Declare @ArrivalDate DATETIME;
    Declare @DepartureDate DATETIME;

    Select @ReservationId = dbo.Reservation_TimeInterval_Record.ReservationId ,@ArrivalDate = dbo.Reservation_TimeInterval_Record.ArrivalTime, @DepartureDate = dbo.Reservation_TimeInterval_Record.DepartureTime
    from inserted join dbo.Reservation_TimeInterval_Record On dbo.Reservation_TimeInterval_Record.ReservationId = inserted.ReservationId; 

    EXEC CalculateParkingFee @ArrivalDate,@DepartureDate,@ReservationId;  -- calcuate parking fees
END;

Go
drop trigger trg_CalculateParkingFee
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go

Create procedure check_slot_status
    @DummySlotNumber int
As
Begin
    
	Declare @Full int = 0;

	Select @Full = count(*) from dbo.ParkingSlots where dbo.ParkingSlots.Status = 'Occupied'

	IF(@Full >= 25 )
	Begin 
	   Print 'Sorry All the slots are Occupied.';
       return 0;
	End

    IF (@DummySlotNumber > 25)
    Begin
        Print 'Slot number should not be greater than the total slots 25.';
        return 0;  
    end

    declare @SlotStatus varchar(20);
    
    Select @SlotStatus = dbo.ParkingSlots.Status
    from dbo.ParkingSlots
    where dbo.ParkingSlots.SlotNumber = @DummySlotNumber;


    IF (@SlotStatus = 'Occupied')
    Begin
        Print 'Slot is already occupied.';
        return 0;
    end

    IF (@SlotStatus = 'Available')
    Begin
        Print 'Slot is available.';
        return 1;
    end

    PRINT 'Invalid status or slot not found.';
    return  0;
END;
GO

Declare @preferedSlot int = 19;
Declare @ReturnValue int;  
Exec @ReturnValue = check_slot_status @preferedSlot;
If( @ReturnValue = 1 )
Begin
   Print 'So Slot can be booked!!'
   Update dbo.ParkingSlots set dbo.ParkingSlots.Status = 'Occupied' where dbo.ParkingSlots.SlotNumber =  @preferedSlot;
End
Else
Begin
   Print 'So Slot cant be booked!!'
End

go
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

go

CREATE PROCEDURE InsertAdminDetails
    @AdminCNIC VARCHAR(20),
    @AdminPhoneNo VARCHAR(15),
    @AdminAddress TEXT,
    @AdminName VARCHAR(100),
    @Password VARCHAR(10)
AS
BEGIN
   
        INSERT INTO dbo.Admins_Details(AdminCNIC, AdminPhoneNo, AdminAddress)
        VALUES (@AdminCNIC, @AdminPhoneNo, @AdminAddress);
        
       
        INSERT INTO Admin_Logins (AdminCNIC, AdminName, Password)
        VALUES (@AdminCNIC, @AdminName, @Password);
        
        SELECT 'Admin account created successfully' AS Result;

END;

Exec InsertAdminDetails '35202','067578','udjfekdn cnkejf','Talha','HiIAmTalha'
go

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE UpdateAdminPassword
    @AdminCNIC VARCHAR(20),
    @OldPassword VARCHAR(10),
    @NewPassword VARCHAR(10)
AS
BEGIN
   IF EXISTS (
    SELECT 1 FROM Admin_Logins 
    WHERE AdminCNIC = @AdminCNIC AND Password = @OldPassword AND @OldPassword <> @NewPassword
)

    BEGIN
        UPDATE Admin_Logins
        SET Password = @NewPassword
        WHERE AdminCNIC = @AdminCNIC;
        
        SELECT 'Password updated successfully' AS Result;
    END
    ELSE
    BEGIN
        SELECT 'Invalid credentials' AS Result;
    END
END;

go

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

EXEC UpdateAdminPassword '35202','HiIAmTalha','ABCD'
SELECT * FROM Admin_Logins WHERE AdminCNIC = '35202';

go

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE findAdmin
    @AdminCNIC VARCHAR(20),
    @Password VARCHAR(10)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Admin_Logins 
               WHERE AdminCNIC = @AdminCNIC AND Password = @Password)
    BEGIN
        SELECT a.AdminName, a.AdminCNIC, ad.AdminPhoneNo, ad.AdminAddress
        FROM Admin_Logins a
        JOIN Admins_Details ad ON a.AdminCNIC = ad.AdminCNIC
        WHERE a.AdminCNIC = @AdminCNIC;
        
        RETURN 1; -- Success
    END
    ELSE
    BEGIN
        SELECT 'Admin Not found within these Deatils' AS Result;
        RETURN 0; -- Failed
    END 
END;

go

EXEC findAdmin '35202','ABCD'
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go

Create Procedure InsertUserDetails
    @UserName varchar(100),
    @UserCNIC varchar(20),
    @UserPhoneNo varchar(15)
AS
Begin
    IF exists (SELECT 1 FROM Users WHERE UserCNIC = @UserCNIC OR UserPhoneNo = @UserPhoneNo)
    Begin
        SELECT 'Duplicate CNIC or Phone Number detected' AS Result;
    End
    else
    Begin
INSERT INTO Users (UserName, UserCNIC, UserPhoneNo)
VALUES (@UserName, @UserCNIC, @UserPhoneNo);
            
SELECT 'User added successfully' AS Result;
    END
END;
go
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create Procedure InsertVehicleDetails
    @LicenseNo varchar(20),
    @Category varchar(10)
AS
Begin
   
    if @Category NOT IN ('Sedan', 'SUV', 'Compact')
    begin
        Select 'Invalid category. Must be Sedan, SUV, or Compact.' AS Result;
        return;
    end
       Insert into Vehicles (LicenseNo, Category)
        values (@LicenseNo, @Category);
        
        Select 'Vehicle added successfully' AS Result;
end;

go
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create procedure InsertReservationDetails
	  @P_LicenseNo varchar(20) ,
	  @P_SlotNumber int ,
	  @P_UserCNIC varchar(20) ,
	  @P_ArrivalTime datetime ,
	  @P_DepartureTime datetime 
As 
Begin

If ( @P_LicenseNo is Null or @P_SlotNumber is null or @P_UserCNIC is NULL or @P_ArrivalTime is null or @P_DepartureTime is NULL )
Begin
   Print 'Please enter valid data to reserve a slot!!!'
   return;
End

IF @P_DepartureTime <= @P_ArrivalTime
BEGIN
    SELECT 'Departure time must be later than arrival time' AS Result;
    RETURN;
END

Insert into dbo.Reservation_Details (LicenseNo , SlotNumber , UserCNIC , PaymentStatus) values ( @P_LicenseNo , @P_SlotNumber , @P_UserCNIC , 'Unpaid' );

Declare @P_RID int = 0;

Select @P_RID = dbo.Reservation_Details.ReservationId from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = @P_LicenseNo 
and dbo.Reservation_Details.SlotNumber = @P_SlotNumber and dbo.Reservation_Details.PaymentStatus = 'Unpaid' and dbo.Reservation_Details.UserCNIC
o= @P_UserCNIC 

Insert into dbo.Reservation_TimeInterval_Record values ( @P_RID , @P_ArrivalTime , @P_DepartureTime );

 Select 'Reservation added successfully' AS Result;

End;

drop procedure InsertReservationDetails
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go
 
Declare @ArrivalTime DATETIME = GETDATE();
Declare @DepartureTime DATETIME = DATEADD(MINUTE, 120, @ArrivalTime);
Declare @UserCnic varchar(20) = '34567890';
Declare @SlotNumber int = 15;
Declare @LicenseNO varchar(20) = 'LEE_677';
Declare @Username varchar(20) = 'AHmed' ;
Declare @Phone varchar(20) = '3456-5759';
Declare @cardet varchar(10) = 'SUV';

Exec InsertUserDetails @Username , @UserCnic , @Phone
Exec InsertVehicleDetails @LicenseNO , @cardet
EXEC InsertReservationDetails @LicenseNo ,@SlotNumber,@UserCnic , @ArrivalTime, @DepartureTime;

go
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

create procedure VehicleCheck
    @LicenseNumber varchar(20)
as
begin
    
    IF exists (
       Select 1 from dbo.Vehicles 
        where dbo.Vehicles.LicenseNo = @LicenseNumber
    )
    BEGIN
	   SELECT 'active reservations found for this vehicle' AS Result;
	    Print 'Active Reservation Found'
        RETURN 1;
    END
    ELSE
    BEGIN
        SELECT 'No active reservations found for this vehicle' AS Result;
        RETURN 0;
    END
END;

Drop procedure VehicleCheck

EXECUTE VehicleCheck 'LEE_677';
select * from Reservation_Details
select * from dbo.Vehicles
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
go


go

CREATE PROCEDURE BookParkingSlot
    @Category VARCHAR(20),
    @SlotNumber INT
AS
BEGIN

    -- Check if slot is available
    IF NOT EXISTS (
        SELECT 1 FROM ParkingSlots 
        WHERE SlotNumber = @SlotNumber AND [Status] = 'Available'
    )
    BEGIN
        SELECT 'Selected slot is not available' AS Result;
        RETURN 0;
    END

  Return 1;
END;

EXEC BookParkingSlot 
    @Category = 'SUV',
    @SlotNumber = 23
go
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Create procedure CalculateFine
     @LicensoNo varchar(20) ,
	 @ActualTime datetime
As
Begin

Declare @ActualArrivalTime datetime ;
Declare @DepartArrivalTime datetime ;
Declare @P_ReservationId int ;
Declare @FineAmount Decimal(10,2) = 0;

Select @P_ReservationId = dbo.Reservation_Details.ReservationId from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = @LicensoNo;

Select @ActualArrivalTime = dbo.Reservation_TimeInterval_Record.ArrivalTime , @DepartArrivalTime = dbo.Reservation_TimeInterval_Record.DepartureTime from 
dbo.Reservation_TimeInterval_Record where dbo.Reservation_TimeInterval_Record.ReservationId =@P_ReservationId ;

If (@ActualTime BETWEEN @ActualArrivalTime AND @DepartArrivalTime)
    Begin
        SET @FineAmount = 0;
    End

    Else If (@ActualTime > @DepartArrivalTime)
    Begin
        Declare @MinutesLate Int;

        Set @MinutesLate = DATEDIFF(MINUTE, @DepartArrivalTime, @ActualTime);

        Set @FineAmount = @MinutesLate * 0.5;
    End

	Update dbo.Reservations_Charges set dbo.Reservations_Charges.Fine = @FineAmount where dbo.Reservations_Charges.ReservationId = @P_ReservationId;
END

Drop procedure CalculateFine

Declare @timenow datetime = getdate();
Exec CalculateFine 'LEE_678',@timenow


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


go

Create view allReservationListed
AS
Select dbo.Reservation_Details.ReservationId , dbo.Reservation_Details.LicenseNo , dbo.Reservation_Details.SlotNumber , dbo.Reservation_Details.UserCNIC , dbo.Reservation_TimeInterval_Record.ArrivalTime , 
dbo.Reservation_TimeInterval_Record.DepartureTime , dbo.Reservations_Charges.ParkingFee , dbo.Reservations_Charges.Fine , dbo.Reservation_Details.PaymentStatus
from dbo.Reservation_Details join dbo.Reservation_TimeInterval_Record On dbo.Reservation_Details.ReservationId = dbo.Reservation_TimeInterval_Record.ReservationId 
join dbo.Reservations_Charges On dbo.Reservation_Details.ReservationId = dbo.Reservations_Charges.ReservationId

go

Select * from allReservationListed

---------------------------------------------------------------------------------------------------------------------------------------------------
go

Create function getFees(@LicNo varchar(20) )
returns int
AS 
Begin

Declare @P_ReservationId int = 0;
   
Select @P_ReservationId = dbo.Reservation_Details.ReservationId from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = @LicNo;

Declare @fees int = 0;

Select @fees = dbo.Reservations_Charges.ParkingFee from dbo.Reservations_Charges where dbo.Reservations_Charges.ReservationId = @P_ReservationId;

if( @fees is not null )
	Begin
		return @fees
	end

return 0
	

End;

go

Create function getFine(@LicNo varchar(20) )
returns int
AS 
Begin

Declare @P_ReservationId int = 0;
   
Select @P_ReservationId = dbo.Reservation_Details.ReservationId from dbo.Reservation_Details where dbo.Reservation_Details.LicenseNo = @LicNo;

Declare @fine decimal(10,2) = 0;

Select @fine = dbo.Reservations_Charges.Fine from dbo.Reservations_Charges where dbo.Reservations_Charges.ReservationId = @P_ReservationId;

if( @fine is not null )
	Begin
		return @fine
	end

return 0
	
End;
--------------------------------------------------------------------------------------------------
go

Create procedure totalExpense
     @LicenseNo varchar(20) ,
	 @TotalAmount int output 
AS
begin
     
	 Select @TotalAmount = dbo.getFees(@LicenseNo)+dbo.getFine(@LicenseNo) from dbo.Reservation_Details 
	 where dbo.Reservation_Details.LicenseNo = @LicenseNo;

end;

go


Declare @License varchar(20) = 'LEE_677'
Declare @Amount int

Exec totalExpense @license , @Amount output

Print 'Total Amount to be paid is : ' + cast(@Amount as varchar(20)) + ' .';

---------------------------------------------------------------------------------------------------------------------------------------------------------
go

create procedure updatepaymentstatus 
   @LicenseNo varchar(20)
As
Begin

Update dbo.Reservation_Details set dbo.Reservation_Details.PaymentStatus = 'Paid' where dbo.Reservation_Details.LicenseNo = @LicenseNo;

End;
go


exec updatepaymentstatus 'LEE_677'

-----------------------------------------------------------------------------------------------------------------------------------------------------------
go

--Select * from dbo.Admins_Details
--Select * from dbo.Admin_Logins
--Select * from dbo.Users
--Select * from dbo.Vehicles
--Select * from dbo.ParkingSlots
--Select * from dbo.Reservation_TimeInterval_Record
--Select * from dbo.Reservations_Charges
--Select * from dbo.Reservation_Details
--Select * from dbo.History_Records
--Select * from dbo.Vehicle_Details
--Select * from dbo.User_History
--Select * from dbo.Charges_History

--drop table dbo.Reservation_TimeInterval_Record
--drop table dbo.Reservations_Charges
--drop table dbo.Reservation_Details
--drop table dbo.ParkingSlots
--drop table dbo.Admin_Logins
--drop table dbo.Admins_Details
--drop table dbo.Charges_History
--drop table dbo.User_History
--drop table dbo.History_Records
--drop table dbo.Vehicle_Details
--drop table dbo.Users
--drop table dbo.Vehicles
