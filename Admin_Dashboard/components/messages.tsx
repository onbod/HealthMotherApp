"use client"

import { useState, useEffect, useRef } from "react"
import {
  MessageSquare,
  Search,
  Clock,
  User,
  Send
} from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"

interface ChatSummary {
  id: string
  userId: string
  healthWorkerId: string
  lastMessage: string
  lastMessageTime: any
  createdAt: any
  unreadCount?: number
}

interface MessageDoc {
  id: string
  senderId: string
  receiverId: string
  text: string
  timestamp: any
}

export function getTotalUnreadCount(chats: ChatSummary[]): number {
  return chats.reduce((sum, chat) => sum + (chat.unreadCount || 0), 0)
}

export function Messages() {
  const [chats, setChats] = useState<ChatSummary[]>([])
  const [selectedChat, setSelectedChat] = useState<ChatSummary | null>(null)
  const [messages, setMessages] = useState<MessageDoc[]>([])
  const [loadingChats, setLoadingChats] = useState(true)
  const [replyContent, setReplyContent] = useState("")
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement | null>(null)
  const currentUserId = "admin"; // Replace with actual user ID from auth

  // Fetch chat list
  useEffect(() => {
    const fetchChats = async () => {
      setLoadingChats(true)
      try {
        // Use dummy data for chats
        setChats([
          { id: "chat1", userId: "Patient A", healthWorkerId: "Health Worker 1", lastMessage: "How are you feeling today?", lastMessageTime: new Date("2023-10-26T10:00:00Z"), createdAt: new Date("2023-10-26T09:00:00Z"), unreadCount: 2 },
          { id: "chat2", userId: "Patient B", healthWorkerId: "Health Worker 2", lastMessage: "I'm feeling better now.", lastMessageTime: new Date("2023-10-26T11:00:00Z"), createdAt: new Date("2023-10-26T10:00:00Z"), unreadCount: 0 },
          { id: "chat3", userId: "Patient C", healthWorkerId: "Health Worker 1", lastMessage: "Can you send me the report?", lastMessageTime: new Date("2023-10-26T12:00:00Z"), createdAt: new Date("2023-10-26T11:00:00Z"), unreadCount: 1 },
        ])
      } catch (error) {
        console.error("Error fetching chats:", error)
      } finally {
        setLoadingChats(false)
      }
    }
    fetchChats()
  }, [])

  // Real-time messages for selected chat
  useEffect(() => {
    if (!selectedChat) return
    // Use dummy data for messages
    setMessages([
      { id: "msg1", senderId: "health_worker", receiverId: "Patient A", text: "I'm feeling better now.", timestamp: new Date("2023-10-26T10:05:00Z") },
      { id: "msg2", senderId: "Patient A", receiverId: "health_worker", text: "Great to hear that!", timestamp: new Date("2023-10-26T10:10:00Z") },
      { id: "msg3", senderId: "Patient A", receiverId: "health_worker", text: "Can you send me the report?", timestamp: new Date("2023-10-26T10:15:00Z") },
      { id: "msg4", senderId: "health_worker", receiverId: "Patient A", text: "Sure, I'll send it now.", timestamp: new Date("2023-10-26T10:20:00Z") },
    ])
  }, [selectedChat])

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" })
    }
  }, [messages])

  const handleSendReply = async () => {
    if (!selectedChat || !replyContent.trim()) return
    setSending(true)
    try {
      // Use dummy data for adding messages
      setMessages(prevMessages => [...prevMessages, {
        id: `msg${prevMessages.length + 1}`,
        senderId: "health_worker",
        receiverId: selectedChat.userId,
        text: replyContent,
        timestamp: new Date(),
      }])
      setReplyContent("")
      // Update lastMessage and lastMessageTime in chat summary
      // This part would typically involve a backend update, but for now, we'll just re-fetch or update locally
      // For simplicity, we'll just re-fetch all chats to reflect the new message
      setChats(prevChats => prevChats.map(chat => {
        if (chat.id === selectedChat.id) {
          return {
            ...chat,
            lastMessage: replyContent,
            lastMessageTime: new Date(),
            unreadCount: 0, // admin just sent
            updatedAt: new Date(),
            updatedBy: currentUserId,
          }
        }
        return chat
      }))
    } catch (error) {
      console.error("Error sending reply:", error)
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="flex h-[80vh] bg-gray-50 rounded-lg shadow overflow-hidden">
      {/* Sidebar */}
      <div className="w-1/4 min-w-[220px] max-w-xs border-r border-gray-200 flex flex-col">
        <div className="p-4 border-b bg-white">
          <h2 className="text-lg font-bold text-maternal-blue-700">Chats</h2>
        </div>
        <div className="flex-1 overflow-y-auto">
          {loadingChats ? (
            <div className="text-center text-gray-500 py-8">Loading chats...</div>
          ) : (
            <div className="divide-y">
              {chats.map(chat => (
                <div
                  key={chat.id}
                  className={`flex items-center gap-2 px-4 py-3 cursor-pointer hover:bg-blue-50 transition ${selectedChat?.id === chat.id ? 'bg-blue-100' : ''}`}
                  onClick={() => setSelectedChat(chat)}
                >
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-maternal-blue-700 truncate">{chat.userId}</div>
                    <div className="text-xs text-gray-500 truncate">{chat.lastMessage}</div>
                  </div>
                  {Number(chat.unreadCount || 0) > 0 && (
                    <span className="ml-2 inline-flex items-center justify-center min-w-[20px] h-5 px-2 rounded-full bg-red-500 text-white text-xs font-bold" title="Unread">
                      {chat.unreadCount || 0}
                    </span>
                  )}
                </div>
              ))}
              {chats.length === 0 && (
                <div className="text-center text-gray-400 py-8">No chats found.</div>
              )}
            </div>
          )}
        </div>
      </div>
      {/* Main Chat Area */}
      <div className="w-3/4 flex flex-col h-full min-h-[80vh]">
        {selectedChat ? (
          <>
            {/* Chat Header */}
            <div className="border-b px-6 py-3 flex items-center gap-2 bg-white sticky top-0 z-10">
              <User className="h-5 w-5 text-maternal-blue-500" />
              <span className="font-semibold text-maternal-blue-700">{selectedChat.userId}</span>
              <span className="ml-auto text-xs text-gray-400">
                Started: {selectedChat.createdAt?.toDate
                  ? selectedChat.createdAt.toDate().toLocaleString()
                  : new Date(selectedChat.createdAt).toLocaleString()}
              </span>
            </div>
            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-6 py-4 bg-gray-50 flex flex-col" style={{ minHeight: 0 }}>
              <div className="flex flex-col gap-2 flex-1 justify-end">
                {messages.map(msg => (
                  <div
                    key={msg.id}
                    className={`flex ${msg.senderId === "health_worker" ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`rounded-2xl px-4 py-2 max-w-[70%] break-words shadow-sm ${msg.senderId === "health_worker" ? 'bg-maternal-blue-600 text-white' : 'bg-white text-gray-900 border'}`}>
                      <div className="text-sm">{msg.text}</div>
                      <div className="text-xs text-gray-300 text-right mt-1">
                        {msg.timestamp?.toDate
                          ? msg.timestamp.toDate().toLocaleString()
                          : new Date(msg.timestamp).toLocaleString()}
                      </div>
                    </div>
                  </div>
                ))}
                <div ref={messagesEndRef} />
                {messages.length === 0 && (
                  <div className="text-center text-gray-400 py-8">No messages yet.</div>
                )}
              </div>
            </div>
            {/* Reply Box */}
            <div className="border-t px-6 py-4 bg-white flex items-center gap-2 sticky bottom-0 z-10">
              <Textarea
                value={replyContent}
                onChange={e => setReplyContent(e.target.value)}
                placeholder="Type your message..."
                rows={2}
                className="flex-1 resize-none"
                disabled={sending}
              />
              <Button
                onClick={handleSendReply}
                className="bg-maternal-blue-600 hover:bg-maternal-blue-700 text-white"
                disabled={sending || !replyContent.trim()}
              >
                <Send className="mr-2 h-4 w-4" />
                Send
              </Button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400">
            Select a chat to view messages
          </div>
        )}
      </div>
    </div>
  )
} 