import 'package:flutter/material.dart';
// Unified ApiConfig lives under config/api_config.dart; no direct usage here, leaving import removed.

class GiveawayChecklist extends StatelessWidget {
  final int userTickets;
  final int totalTickets;
  final bool isSubscriptionChecked;
  final bool isCheckButtonLoading;
  final bool isCheckButtonSuccess;
  final bool isCheckButtonError;
  final VoidCallback onCheckPressed;
  final VoidCallback onInviteFriendsPressed;

  const GiveawayChecklist({
    super.key,
    required this.userTickets,
    required this.totalTickets,
    required this.isSubscriptionChecked,
    required this.isCheckButtonLoading,
    required this.isCheckButtonSuccess,
    required this.isCheckButtonError,
    required this.onCheckPressed,
    required this.onInviteFriendsPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Задание 1: Подписка на папку
    final bool task1Completed = userTickets >= 1;
    final String task1Progress = task1Completed ? '1/1' : '0/1';
    
    // Задание 2: Приглашение друзей
    final int friendTickets = userTickets > 1 ? userTickets - 1 : 0;
    final int maxFriendTickets = 10;
    final String task2Progress = '$friendTickets/$maxFriendTickets';
    
    // Итог
    final int totalEarnedTickets = userTickets;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Задания для получения билетов',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 16),
          
          // Задание 1: Подписка на папку
          _buildTaskItem(
            context: context,
            title: 'Подписаться на Telegram-папку',
            description: 'Даёт 1 билет',
            progress: task1Progress,
            isCompleted: task1Completed,
            isCheckButton: true,
            onCheckPressed: onCheckPressed,
            isLoading: isCheckButtonLoading,
            isSuccess: isCheckButtonSuccess,
            isError: isCheckButtonError,
          ),
          
          const SizedBox(height: 12),
          
          // Задание 2: Приглашение друзей
          _buildTaskItem(
            context: context,
            title: 'Пригласить друзей',
            description: 'Даёт 1 билет за каждого приглашённого друга, максимум 10 билетов',
            progress: task2Progress,
            isCompleted: friendTickets > 0,
            isCheckButton: false,
            onCheckPressed: onInviteFriendsPressed,
            isLoading: false,
            isSuccess: false,
            isError: false,
          ),
          
          const SizedBox(height: 16),
          
          // Итог
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.pink.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итог:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                  ),
                ),
                Text(
                  '$totalEarnedTickets билетов',
                  style: TextStyle(
                    color: Colors.pink[300],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({
    required BuildContext context,
    required String title,
    required String description,
    required String progress,
    required bool isCompleted,
    required bool isCheckButton,
    required VoidCallback onCheckPressed,
    required bool isLoading,
    required bool isSuccess,
    required bool isError,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? Colors.green.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted 
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Иконка статуса
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted 
                      ? Colors.green
                      : Colors.grey.withOpacity(0.5),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Заголовок
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
              
              // Прогресс
              Text(
                progress,
                style: TextStyle(
                  color: isCompleted 
                      ? Colors.green[300]
                      : Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'OpenSans',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Описание
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'OpenSans',
            ),
          ),
          
          // Кнопка проверки (только для задания 1)
          if (isCheckButton) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildCheckButton(
                isLoading: isLoading,
                isSuccess: isSuccess,
                isError: isError,
                onPressed: onCheckPressed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckButton({
    required bool isLoading,
    required bool isSuccess,
    required bool isError,
    required VoidCallback onPressed,
  }) {
    Color buttonColor = Colors.pink;
    String buttonText = 'Проверить подписку';
    IconData? icon;

    if (isLoading) {
      buttonColor = Colors.grey;
      buttonText = 'Проверяем...';
      icon = Icons.hourglass_empty;
    } else if (isSuccess) {
      buttonColor = Colors.green;
      buttonText = 'Подписка подтверждена';
      icon = Icons.check;
    } else if (isError) {
      buttonColor = Colors.red;
      buttonText = 'Ошибка проверки';
      icon = Icons.error;
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 