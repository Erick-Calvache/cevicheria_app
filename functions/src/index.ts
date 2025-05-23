import * as functions from 'firebase-functions/v1';

import * as admin from 'firebase-admin';

admin.initializeApp();

export const notificarNuevoPedido = functions.firestore
  .document('pedidos/{pedidoId}')
  .onCreate(async (snapshot, context) => {
    const nuevoPedido = snapshot.data();

    if (!nuevoPedido) {
      console.log('No hay datos en el nuevo pedido');
      return;
    }

    const message: admin.messaging.Message = {
      notification: {
        title: '🍤 Nuevo pedido',
        body: `Pedido confirmado por $${nuevoPedido.total}`,
      },
      data: {
        screen: 'pedidos',
      },
      topic: 'nuevos_pedidos',
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            category: 'NEW_ORDER_CATEGORY',
          },
        },
      },
      webpush: {
        headers: {
          Urgency: 'high',
        },
        notification: {
          icon: '/assets/icons/icon-192x192.png',
          actions: [{ action: 'open_pedidos', title: 'Ver pedidos' }],
        },
      },
    };
  });
