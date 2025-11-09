import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/usecases/group_usecases.dart';
import '../../domain/providers/domain_providers.dart';
import '../../core/utils/logger.dart';

/// Estado de grupos para UI
class GroupsState {
  final bool isLoading;
  final List<GroupEntity> groups;
  final String? error;
  final GroupEntity? selectedGroup;

  const GroupsState({
    this.isLoading = false,
    this.groups = const [],
    this.error,
    this.selectedGroup,
  });

  GroupsState copyWith({
    bool? isLoading,
    List<GroupEntity>? groups,
    String? error,
    GroupEntity? selectedGroup,
  }) {
    return GroupsState(
      isLoading: isLoading ?? this.isLoading,
      groups: groups ?? this.groups,
      error: error,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}

/// Notifier para gestión de grupos usando Clean Architecture
class GroupsNotifier extends StateNotifier<GroupsState> {
  final GetUserGroupsUseCase _getUserGroupsUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final JoinGroupUseCase _joinGroupUseCase;
  final LeaveGroupUseCase _leaveGroupUseCase;

  GroupsNotifier({
    required GetUserGroupsUseCase getUserGroupsUseCase,
    required CreateGroupUseCase createGroupUseCase,
    required JoinGroupUseCase joinGroupUseCase,
    required LeaveGroupUseCase leaveGroupUseCase,
  })  : _getUserGroupsUseCase = getUserGroupsUseCase,
        _createGroupUseCase = createGroupUseCase,
        _joinGroupUseCase = joinGroupUseCase,
        _leaveGroupUseCase = leaveGroupUseCase,
        super(const GroupsState());

  /// Cargar todos los grupos del usuario
  Future<void> loadGroups() async {
    AppLogger.info('[GROUPS_NOTIFIER] 📥 Cargando grupos...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final groups = await _getUserGroupsUseCase.call();
      
      state = state.copyWith(
        isLoading: false,
        groups: groups,
      );
      
      AppLogger.info('[GROUPS_NOTIFIER] ✅ ${groups.length} grupos cargados');
    } catch (e) {
      AppLogger.error('[GROUPS_NOTIFIER] ❌ Error cargando grupos', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Crear un nuevo grupo
  Future<void> createGroup({
    required String name,
    required String description,
    required GroupTypeEntity type,
  }) async {
    AppLogger.info('[GROUPS_NOTIFIER] 📤 Creando grupo: $name');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newGroup = await _createGroupUseCase.call(
        CreateGroupParams(
          name: name,
          description: description,
          type: type,
        ),
      );

      // Agregar el nuevo grupo a la lista
      final updatedGroups = [...state.groups, newGroup];
      
      state = state.copyWith(
        isLoading: false,
        groups: updatedGroups,
        selectedGroup: newGroup,
      );
      
      AppLogger.info('[GROUPS_NOTIFIER] ✅ Grupo creado: ${newGroup.id}');
    } catch (e) {
      AppLogger.error('[GROUPS_NOTIFIER] ❌ Error creando grupo', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Unirse a un grupo mediante código de invitación
  Future<void> joinGroup(String inviteCode) async {
    AppLogger.info('[GROUPS_NOTIFIER] 📤 Uniéndose a grupo: $inviteCode');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final group = await _joinGroupUseCase.call(
        JoinGroupParams(inviteCode: inviteCode),
      );

      // Agregar el grupo a la lista si no existe
      final existingIndex = state.groups.indexWhere((g) => g.id == group.id);
      final updatedGroups = existingIndex >= 0
          ? state.groups
          : [...state.groups, group];

      state = state.copyWith(
        isLoading: false,
        groups: updatedGroups,
        selectedGroup: group,
      );
      
      AppLogger.info('[GROUPS_NOTIFIER] ✅ Unido al grupo: ${group.name}');
    } catch (e) {
      AppLogger.error('[GROUPS_NOTIFIER] ❌ Error uniéndose a grupo', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Salir de un grupo
  Future<void> leaveGroup(String groupId) async {
    AppLogger.info('[GROUPS_NOTIFIER] 📤 Saliendo del grupo: $groupId');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _leaveGroupUseCase.call(
        LeaveGroupParams(groupId: groupId),
      );

      // Remover el grupo de la lista
      final updatedGroups = state.groups.where((g) => g.id != groupId).toList();
      
      state = state.copyWith(
        isLoading: false,
        groups: updatedGroups,
        selectedGroup: state.selectedGroup?.id == groupId ? null : state.selectedGroup,
      );
      
      AppLogger.info('[GROUPS_NOTIFIER] ✅ Salido del grupo exitosamente');
    } catch (e) {
      AppLogger.error('[GROUPS_NOTIFIER] ❌ Error saliendo del grupo', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Seleccionar un grupo
  void selectGroup(GroupEntity? group) {
    AppLogger.info('[GROUPS_NOTIFIER] Seleccionando grupo: ${group?.name ?? 'ninguno'}');
    state = state.copyWith(selectedGroup: group);
  }

  /// Limpiar error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Refrescar grupos (force reload)
  Future<void> refreshGroups() async {
    AppLogger.info('[GROUPS_NOTIFIER] 🔄 Refrescando grupos...');
    await loadGroups();
  }
}

// ============ PROVIDERS ============

/// Provider para GroupsNotifier
final groupsNotifierProvider = StateNotifierProvider<GroupsNotifier, GroupsState>((ref) {
  return GroupsNotifier(
    getUserGroupsUseCase: ref.watch(getUserGroupsUseCaseProvider),
    createGroupUseCase: ref.watch(createGroupUseCaseProvider),
    joinGroupUseCase: ref.watch(joinGroupUseCaseProvider),
    leaveGroupUseCase: ref.watch(leaveGroupUseCaseProvider),
  );
});

/// Provider conveniente para acceder a la lista de grupos
final groupsListProvider = Provider<List<GroupEntity>>((ref) {
  return ref.watch(groupsNotifierProvider).groups;
});

/// Provider conveniente para acceder al grupo seleccionado
final selectedGroupProvider = Provider<GroupEntity?>((ref) {
  return ref.watch(groupsNotifierProvider).selectedGroup;
});

/// Provider conveniente para saber si está cargando
final groupsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(groupsNotifierProvider).isLoading;
});
