import 'auth_service.dart';
import 'shift_service.dart';
import '../models/shift.dart';

class DataSeedingService {
  static final DataSeedingService _instance = DataSeedingService._internal();
  static DataSeedingService get instance => _instance;
  DataSeedingService._internal();

  final AuthService _authService = AuthService.instance;
  final ShiftService _shiftService = ShiftService.instance;

  /// Seed the database with essential data (user accounts and sample shifts)
  Future<void> seedDatabase() async {
    try {
      print('🌱 SEEDER: Starting database seeding...');
      
      // Create essential user accounts for login
      await _authService.createSampleUsers();
      print('👥 SEEDER: User accounts created');

      // Always create sample shifts for testing
      await _createSampleShifts();
      print('📋 SEEDER: Sample shifts creation attempted');

      print('🎉 SEEDER: Database seeding completed');
    } catch (e) {
      print('❌ SEEDER: Error initializing database: $e');
    }
  }

  /// Create 5 sample shifts for testing
  Future<void> _createSampleShifts() async {
    try {
      final now = DateTime.now();
      
      // Sample shifts with different types and times
      final sampleShifts = [
        Shift(
          id: 'shift_001',
          title: 'Security Guard - Shopping Mall',
          description: 'Patrol shopping mall premises, monitor CCTV, and ensure customer safety',
          locationId: 'loc_001',
          locationName: 'Westfield Shopping Centre',
          locationAddress: '123 High Street, London, SW1A 1AA',
          startTime: now.add(const Duration(days: 1, hours: 9)),
          endTime: now.add(const Duration(days: 1, hours: 17)),
          shiftType: ShiftType.stewardShift,
          hourlyRate: 12.50,
          requiredGuards: 2,
          assignedGuards: 0,
          status: ShiftStatus.open,
          isUrgent: false,
          requiredCertifications: ['Security License', 'Customer Service'],
          specialInstructions: 'Must be presentable and professional. Experience with retail security preferred.',
          createdBy: 'admin_001',
          createdAt: now,
          updatedAt: now,
        ),
        Shift(
          id: 'shift_002',
          title: 'Event Steward - Concert Venue',
          description: 'Crowd control and customer assistance at live music event',
          locationId: 'loc_002',
          locationName: 'O2 Arena',
          locationAddress: 'Peninsula Square, London, SE10 0DX',
          startTime: now.add(const Duration(days: 3, hours: 18)),
          endTime: now.add(const Duration(days: 4, hours: 1)),
          shiftType: ShiftType.stewardShift,
          hourlyRate: 11.00,
          requiredGuards: 5,
          assignedGuards: 0,
          status: ShiftStatus.open,
          isUrgent: false,
          requiredCertifications: ['Crowd Control', 'First Aid'],
          specialInstructions: 'High-energy environment. Must be comfortable working with large crowds.',
          createdBy: 'admin_001',
          createdAt: now,
          updatedAt: now,
        ),
        Shift(
          id: 'shift_003',
          title: 'SIA Door Supervisor - Nightclub',
          description: 'Door supervision and security at busy nightclub venue',
          locationId: 'loc_003',
          locationName: 'Ministry of Sound',
          locationAddress: '103 Gaunt Street, London, SE1 6DP',
          startTime: now.add(const Duration(days: 5, hours: 21)),
          endTime: now.add(const Duration(days: 6, hours: 4)),
          shiftType: ShiftType.siaShift,
          hourlyRate: 15.00,
          requiredGuards: 3,
          assignedGuards: 0,
          status: ShiftStatus.open,
          isUrgent: true,
          requiredCertifications: ['SIA License', 'Conflict Resolution'],
          specialInstructions: 'Must have valid SIA license. Experience with nightclub security essential.',
          createdBy: 'admin_001',
          createdAt: now,
          updatedAt: now,
        ),
        Shift(
          id: 'shift_004',
          title: 'Corporate Security - Office Building',
          description: 'Reception security and access control for corporate headquarters',
          locationId: 'loc_004',
          locationName: 'Canary Wharf Tower',
          locationAddress: '1 Canada Square, London, E14 5AB',
          startTime: now.add(const Duration(days: 7, hours: 8)),
          endTime: now.add(const Duration(days: 7, hours: 18)),
          shiftType: ShiftType.event,
          hourlyRate: 13.75,
          requiredGuards: 1,
          assignedGuards: 0,
          status: ShiftStatus.open,
          isUrgent: false,
          requiredCertifications: ['Security License', 'Access Control', 'Customer Service'],
          specialInstructions: 'Professional appearance required. Must be comfortable with corporate environment.',
          createdBy: 'admin_001',
          createdAt: now,
          updatedAt: now,
        ),
        Shift(
          id: 'shift_005',
          title: 'Emergency Response - Hospital',
          description: 'Security support for hospital emergency department',
          locationId: 'loc_005',
          locationName: 'St. Thomas Hospital',
          locationAddress: 'Westminster Bridge Road, London, SE1 7EH',
          startTime: now.add(const Duration(days: 2, hours: 22)),
          endTime: now.add(const Duration(days: 3, hours: 6)),
          shiftType: ShiftType.emergency,
          hourlyRate: 16.25,
          requiredGuards: 2,
          assignedGuards: 0,
          status: ShiftStatus.open,
          isUrgent: true,
          requiredCertifications: ['Security License', 'First Aid', 'Emergency Response'],
          specialInstructions: 'Medical environment. Must remain calm under pressure and follow strict protocols.',
          createdBy: 'admin_001',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      // Create each shift
      print('📋 SHIFTS: Creating ${sampleShifts.length} sample shifts...');
      for (int i = 0; i < sampleShifts.length; i++) {
        final shift = sampleShifts[i];
        print('📝 SHIFTS: Creating shift ${i + 1}: ${shift.title}');
        try {
          await _shiftService.createShift(shift);
          print('✅ SHIFTS: Successfully created shift: ${shift.title}');
        } catch (e) {
          print('❌ SHIFTS: Failed to create shift ${shift.title}: $e');
        }
      }

      print('🎯 SHIFTS: Finished creating ${sampleShifts.length} sample shifts');
    } catch (e) {
      print('Error creating sample shifts: $e');
    }
  }

  /// Check if database needs seeding
  Future<bool> needsSeeding() async {
    try {
      // For debugging - always seed to ensure shifts are created
      print('🔍 SEEDER: FORCING seeding to ensure shifts are created');
      return true;
      
      // TODO: Restore proper seeding check after shifts are working
      /*
      final loginResult = await _authService.login(
        email: 'admin@mankindportal.com', 
        password: 'admin123'
      );
      final needsUsers = !loginResult.success;
      print('Seeding check - Needs users: $needsUsers');
      return needsUsers;
      */
    } catch (e) {
      print('Error checking if seeding needed: $e');
      return true;
    }
  }
}
