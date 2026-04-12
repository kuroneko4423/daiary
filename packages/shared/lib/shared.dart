/// Shared domain models, interfaces, core utilities and UI for dAIary.
library;

// Core
export 'core/constants/app_constants.dart';
export 'core/constants/share_constants.dart';
export 'core/exceptions/app_exception.dart';
export 'core/extensions/context_extensions.dart';
export 'core/utils/validators.dart';
export 'core/widgets/app_error_widget.dart';
export 'core/widgets/loading_widget.dart';

// Config
export 'config/theme.dart';

// Domain models
export 'domain/models/photo.dart';
export 'domain/models/album.dart';
export 'domain/models/generation_result.dart';
export 'domain/models/caption_result.dart';
export 'domain/models/hashtag_result.dart';

// Domain interfaces
export 'domain/interfaces/ai_service.dart';
export 'domain/interfaces/photo_repository.dart';
export 'domain/interfaces/album_repository.dart';

// Services
export 'services/share_service.dart';

// Features - Navigation
export 'features/navigation/main_shell.dart';

// Features - Camera
export 'features/camera/presentation/widgets/camera_controls.dart';
export 'features/camera/presentation/providers/camera_state.dart';

// Features - Album
export 'features/album/presentation/widgets/album_card.dart';
export 'features/album/presentation/providers/album_state.dart';

// Features - AI Generate
export 'features/ai_generate/presentation/widgets/result_card.dart';
export 'features/ai_generate/presentation/widgets/style_selector.dart';
export 'features/ai_generate/presentation/providers/ai_generate_state.dart';

// Features - Settings
export 'features/settings/presentation/providers/settings_state.dart';
export 'features/settings/presentation/widgets/settings_dialogs.dart';
