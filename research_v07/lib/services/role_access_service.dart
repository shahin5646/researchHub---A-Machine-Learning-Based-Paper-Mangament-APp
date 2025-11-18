import '../models/user.dart'; // Updated to use user.dart for UserRole

class RoleBasedAccessControl {
  // Paper Management Permissions
  static bool canUploadPapers(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.admin:
        return true;
      case UserRole.student:
        return true; // Students can upload in this academic platform
      case UserRole.guest:
        return false;
    }
  }

  static bool canEditOwnPapers(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.admin:
        return true;
      case UserRole.guest:
        return false;
    }
  }

  static bool canDeleteOwnPapers(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.admin:
        return true;
      case UserRole.guest:
        return false;
    }
  }

  static bool canDeleteAnyPaper(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return true;
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  static bool canViewPrivatePapers(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return true;
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false; // Only own private papers
    }
  }

  // User Management Permissions
  static bool canManageUsers(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return true;
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  static bool canModerateComments(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
        return true;
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  static bool canCreateCategories(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
        return true;
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  // Social Features Permissions
  static bool canComment(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.admin:
        return true;
      case UserRole.guest:
        return false;
    }
  }

  static bool canReact(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.admin:
        return true;
      case UserRole.guest:
        return false;
    }
  }

  static bool canFollowUsers(UserRole role) {
    switch (role) {
      case UserRole.professor:
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.admin:
        return true;
      case UserRole.guest:
        return false;
    }
  }

  // Advanced Features Permissions
  static bool canAccessAnalytics(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
        return true;
      case UserRole.researcher:
        return true; // Limited analytics
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  static bool canExportData(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
      case UserRole.researcher:
        return true;
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  // Upload Limits
  static int getMaxPapersPerDay(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return -1; // Unlimited
      case UserRole.professor:
        return 10;
      case UserRole.researcher:
        return 8;
      case UserRole.student:
        return 5;
      case UserRole.guest:
        return 0;
    }
  }

  static int getMaxFileSizeMB(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 100;
      case UserRole.professor:
        return 50;
      case UserRole.researcher:
        return 30;
      case UserRole.student:
        return 20;
      case UserRole.guest:
        return 0;
    }
  }

  // UI Features
  static bool canSeeAdvancedSearch(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
      case UserRole.researcher:
        return true;
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  static bool canAccessBulkOperations(UserRole role) {
    switch (role) {
      case UserRole.admin:
      case UserRole.professor:
        return true;
      case UserRole.researcher:
      case UserRole.student:
      case UserRole.guest:
        return false;
    }
  }

  // Helper method to get role display name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Student';
      case UserRole.researcher:
        return 'Researcher';
      case UserRole.professor:
        return 'Professor';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.guest:
        return 'Guest';
    }
  }

  // Helper method to get role description
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Can upload papers, comment, and follow users';
      case UserRole.researcher:
        return 'Enhanced features for research activities';
      case UserRole.professor:
        return 'Full access with moderation capabilities';
      case UserRole.admin:
        return 'Complete system administration access';
      case UserRole.guest:
        return 'Read-only access to public content';
    }
  }

  // Helper method to get role badge color
  static String getRoleBadgeColor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return '#4CAF50'; // Green
      case UserRole.researcher:
        return '#2196F3'; // Blue
      case UserRole.professor:
        return '#9C27B0'; // Purple
      case UserRole.admin:
        return '#F44336'; // Red
      case UserRole.guest:
        return '#757575'; // Grey
    }
  }
}
