ild: OutlinedButton.icon(
                                      onPressed: phone.isEmpty
                                          ? null
                                          : () => _contactAlly(phone, name),
                                      icon: const Icon(Icons.phone, size: 18),
                                      label: const Text('Llamar'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: phone.isEmpty
                                          ? null
                                          : () => _contactAlly(phone, name, whatsapp: true),
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('WhatsApp'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
