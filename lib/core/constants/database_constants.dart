class DatabaseConstants {
  // Database configuration
  static const String databaseName = 'mankind_portal.db';
  static const int databaseVersion = 3;

  // Table names
  static const String usersTable = 'users';
  static const String userProfilesTable = 'user_profiles';
  static const String shiftsTable = 'shifts';
  static const String shiftAssignmentsTable = 'shift_assignments';
  static const String payrollEntriesTable = 'payroll_entries';
  static const String companyCodesTable = 'company_codes';
  static const String bookingsTable = 'bookings';
  static const String messagesTable = 'messages';

  // User table columns
  static const String userId = 'id';
  static const String userFirstName = 'first_name';
  static const String userLastName = 'last_name';
  static const String userEmail = 'email';
  static const String userPhoneNumber = 'phone_number';
  static const String userPasswordHash = 'password_hash';
  static const String userType = 'user_type';
  static const String userProfileImageUrl = 'profile_image_url';
  static const String userIsActive = 'is_active';
  static const String userIsApproved = 'is_approved';
  static const String userCreatedAt = 'created_at';
  static const String userUpdatedAt = 'updated_at';

  // User profile table columns
  static const String profileUserId = 'user_id';
  static const String profileLicenseNumber = 'license_number';
  static const String profileLicenseExpiry = 'license_expiry';
  static const String profileCertifications = 'certifications';
  static const String profileHourlyRate = 'hourly_rate';
  static const String profileEmergencyContactName = 'emergency_contact_name';
  static const String profileEmergencyContactPhone = 'emergency_contact_phone';
  static const String profileAddress = 'address';

  // Shift table columns
  static const String shiftId = 'id';
  static const String shiftTitle = 'title';
  static const String shiftDescription = 'description';
  static const String shiftLocationId = 'location_id';
  static const String shiftLocationName = 'location_name';
  static const String shiftLocationAddress = 'location_address';
  static const String shiftStartTime = 'start_time';
  static const String shiftEndTime = 'end_time';
  static const String shiftHourlyRate = 'hourly_rate';
  static const String shiftRequiredGuards = 'required_guards';
  static const String shiftAssignedGuards = 'assigned_guards';
  static const String shiftRequiredSiaGuards = 'required_sia_guards';
  static const String shiftRequiredStewardGuards = 'required_steward_guards';
  static const String shiftStatus = 'status';
  static const String shiftType = 'shift_type';
  static const String shiftCreatedBy = 'created_by';
  static const String shiftCreatedAt = 'created_at';
  static const String shiftUpdatedAt = 'updated_at';
  static const String shiftRequiredCertifications = 'required_certifications';
  static const String shiftSpecialInstructions = 'special_instructions';
  static const String shiftUniformRequirements = 'uniform_requirements';
  static const String shiftIsUrgent = 'is_urgent';

  // Shift assignment table columns
  static const String assignmentId = 'id';
  static const String assignmentShiftId = 'shift_id';
  static const String assignmentUserId = 'user_id';
  static const String assignmentUserName = 'user_name';
  static const String assignmentStatus = 'status';
  static const String assignmentAssignedAt = 'assigned_at';
  static const String assignmentNotes = 'notes';

  // Payroll entry table columns
  static const String payrollId = 'id';
  static const String payrollUserId = 'user_id';
  static const String payrollShiftId = 'shift_id';
  static const String payrollShiftTitle = 'shift_title';
  static const String payrollShiftDate = 'shift_date';
  static const String payrollStartTime = 'start_time';
  static const String payrollEndTime = 'end_time';
  static const String payrollHoursWorked = 'hours_worked';
  static const String payrollHourlyRate = 'hourly_rate';
  static const String payrollTotalPay = 'total_pay';
  static const String payrollStatus = 'status';
  static const String payrollCreatedAt = 'created_at';
  static const String payrollConfirmedAt = 'confirmed_at';
  static const String payrollNotes = 'notes';

  // Company code table columns
  static const String companyCodeId = 'id';
  static const String companyCodeCode = 'code';
  static const String companyCodeCompanyName = 'company_name';
  static const String companyCodeIsActive = 'is_active';
  static const String companyCodeCreatedAt = 'created_at';
  static const String companyCodeExpiresAt = 'expires_at';
  static const String companyCodeCreatedBy = 'created_by';
  static const String companyCodeMaxUses = 'max_uses';
  static const String companyCodeCurrentUses = 'current_uses';

  // Booking table columns
  static const String bookingId = 'id';
  static const String bookingShiftId = 'shift_id';
  static const String bookingUserId = 'user_id';
  static const String bookingStatus = 'status';
  static const String bookingDate = 'booking_date';
  static const String bookingNotes = 'notes';
  static const String bookingCreatedAt = 'created_at';
  static const String bookingUpdatedAt = 'updated_at';

  // Message table columns
  static const String messageId = 'id';
  static const String messageFromUserId = 'from_user_id';
  static const String messageFromUserName = 'from_user_name';
  static const String messageFromUserEmail = 'from_user_email';
  static const String messageToUserId = 'to_user_id';
  static const String messageSubject = 'subject';
  static const String messageContent = 'content';
  static const String messageCreatedAt = 'created_at';
  static const String messageIsRead = 'is_read';
  static const String messageReplyToMessageId = 'reply_to_message_id';
}
