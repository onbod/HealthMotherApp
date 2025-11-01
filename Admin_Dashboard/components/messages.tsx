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
  chatId: string
  senderId: string
  receiverId: string
  text: string
  timestamp: any
  read?: boolean // Added for unread count calculation
}

export function getTotalUnreadCount(chats: ChatSummary[]): number {
  return chats.reduce((sum, chat) => sum + (chat.unreadCount || 0), 0)
}

export function Messages() {
  const [chats, setChats] = useState<ChatSummary[]>([])
  const [selectedChat, setSelectedChat] = useState<ChatSummary | null>(null)
  const [messages, setMessages] = useState<MessageDoc[]>([])
  const [allMessages, setAllMessages] = useState<MessageDoc[]>([])
  const [loadingChats, setLoadingChats] = useState(true)
  const [replyContent, setReplyContent] = useState("")
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement | null>(null)
  const currentUserId = "health_worker"; // Or "admin" or get from auth

  // Fetch all messages and group by chat_id
  useEffect(() => {
    const fetchChats = async () => {
      setLoadingChats(true)
      try {
        const res = await fetch("https://health-fhir-backend-production-6ae1.up.railway.app/api/chat_message")
        const data = await res.json()
        setAllMessages(data)
        // Group messages by chat_id
        const chatMap: { [chatId: string]: MessageDoc[] } = {}
        data.forEach((msg: any) => {
          if (!chatMap[msg.chat_id]) chatMap[msg.chat_id] = []
          chatMap[msg.chat_id].push({
            id: msg.id,
            chatId: msg.chat_id,
            senderId: msg.sender_id,
            receiverId: msg.receiver_id,
            text: msg.message,
            timestamp: msg.timestamp,
            read: msg.is_read,
          })
        })
        const chatSummaries: ChatSummary[] = Object.entries(chatMap).map(([chatId, msgs]) => {
          const sortedMsgs = msgs.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
          const lastMsg = sortedMsgs[sortedMsgs.length - 1]
          return {
            id: chatId, // chatId is the string identifier for the chat
            userId: lastMsg.senderId === currentUserId ? lastMsg.receiverId : lastMsg.senderId,
            healthWorkerId: lastMsg.senderId === currentUserId ? currentUserId : lastMsg.senderId,
            lastMessage: lastMsg.text,
            lastMessageTime: lastMsg.timestamp,
            createdAt: sortedMsgs[0].timestamp,
            unreadCount: sortedMsgs.filter(m => !m.read && m.receiverId === currentUserId).length,
          }
        })
        setChats(chatSummaries)
      } catch (error) {
        console.error("Error fetching chats:", error)
        setChats([])
      } finally {
        setLoadingChats(false)
      }
    }
    fetchChats()
  }, [])

  // When a chat is selected, show only valid messages for that chat_id
  useEffect(() => {
    if (!selectedChat) return
    setMessages(
      allMessages
        .filter(m => m.chatId === selectedChat.id && m.text && m.senderId)
        .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
    )
  }, [selectedChat, allMessages])

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
      const chatMessages = allMessages.filter(m => m.chatId === selectedChat.id)
      let msg, newMsg
      if (chatMessages.length > 0) {
        // Reply to the last message
        const lastMessage = chatMessages[chatMessages.length - 1]
        const originalMessageId = lastMessage.id
        const res = await fetch(`https://health-fhir-backend-production-6ae1.up.railway.app/api/chat_message/reply/${originalMessageId}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            reply: replyContent,
            health_worker_id: 'health_worker',
          })
        })
        if (!res.ok) throw new Error('Failed to send reply')
        msg = await res.json()
        newMsg = {
          id: msg.id,
          chatId: msg.chat_id || msg.chatId || selectedChat.id,
          senderId: msg.sender_id || msg.senderId || 'health_worker',
          receiverId: msg.receiver_id || msg.receiverId || selectedChat.userId,
          text: msg.message || msg.reply || replyContent,
          timestamp: msg.timestamp || new Date().toISOString(),
          read: msg.is_read ?? msg.read ?? false,
        }
      } else {
        // No previous messages, create a new message
        const res = await fetch(`https://health-fhir-backend-production-6ae1.up.railway.app/api/chat_message/chat/${selectedChat.id}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            sender_id: 'health_worker',
            receiver_id: selectedChat.userId,
            message: replyContent,
            is_read: false,
            timestamp: new Date().toISOString(),
          })
        })
        if (!res.ok) throw new Error('Failed to send message')
        msg = await res.json()
        newMsg = {
          id: msg.id,
          chatId: msg.chat_id || msg.chatId || selectedChat.id,
          senderId: msg.sender_id || msg.senderId || 'health_worker',
          receiverId: msg.receiver_id || msg.receiverId || selectedChat.userId,
          text: msg.message || replyContent,
          timestamp: msg.timestamp || new Date().toISOString(),
          read: msg.is_read ?? msg.read ?? false,
        }
      }
      setMessages(prev => [...prev, newMsg])
      setAllMessages(prev => [...prev, newMsg])
      setReplyContent("")
    } catch (error) {
      alert("Error sending reply: " + (error as any).message)
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
                    <div className="font-semibold text-maternal-blue-700 truncate">{chat.userId || chat.id}</div>
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
                    className={`flex ${msg.senderId === 'health_worker' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`rounded-2xl px-4 py-2 max-w-[70%] break-words shadow-sm ${msg.senderId === 'health_worker' ? 'bg-maternal-blue-600 text-white' : 'bg-white text-gray-900 border'}`}>
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