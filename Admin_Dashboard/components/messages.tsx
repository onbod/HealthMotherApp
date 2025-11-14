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
  id: string | number // thread_id
  threadId: string | number
  userId: string
  patientId?: number
  patientName?: string
  patientIdentifier?: string
  healthWorkerId: string
  lastMessage: string
  lastMessageTime: any
  createdAt: any
  unreadCount?: number
}

interface MessageDoc {
  id: string | number
  threadId: string | number
  senderId: string
  receiverId: string
  text: string
  timestamp: any
  read?: boolean
  senderType?: string
}

const API_BASE_URL = "https://health-fhir-backend-production-6ae1.up.railway.app"

export function getTotalUnreadCount(chats: ChatSummary[]): number {
  return chats.reduce((sum, chat) => sum + (chat.unreadCount || 0), 0)
}

export function Messages() {
  const [chats, setChats] = useState<ChatSummary[]>([])
  const [selectedChat, setSelectedChat] = useState<ChatSummary | null>(null)
  const [messages, setMessages] = useState<MessageDoc[]>([])
  const [allMessages, setAllMessages] = useState<MessageDoc[]>([])
  const [loadingChats, setLoadingChats] = useState(true)
  const [loadingMessages, setLoadingMessages] = useState(false)
  const [replyContent, setReplyContent] = useState("")
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement | null>(null)
  const pollingIntervalRef = useRef<NodeJS.Timeout | null>(null)
  const lastMessageCountRef = useRef<number>(0)
  const currentUserId = "health_worker"; // Or "admin" or get from auth

  // Fetch chat threads and messages
  useEffect(() => {
    const fetchChats = async () => {
      setLoadingChats(true)
      try {
        // Try new endpoints first (chat_threads and chat_messages)
        let threads: any[] = []
        let allMsgs: any[] = []
        
        try {
          const threadsRes = await fetch(`${API_BASE_URL}/chat_threads`)
          if (threadsRes.ok) {
            const threadsData = await threadsRes.json()
            threads = Array.isArray(threadsData) ? threadsData : (threadsData.data || [])
            console.log('Fetched threads:', threads.length, threads)
          }
        } catch (e) {
          console.warn('Failed to fetch chat_threads, trying legacy endpoint:', e)
        }
        
        try {
          const messagesRes = await fetch(`${API_BASE_URL}/chat_messages`)
          if (messagesRes.ok) {
            const messagesData = await messagesRes.json()
            allMsgs = Array.isArray(messagesData) ? messagesData : (messagesData.data || [])
            console.log('Fetched messages:', allMsgs.length, allMsgs)
          }
        } catch (e) {
          console.warn('Failed to fetch chat_messages, trying legacy endpoint:', e)
        }
        
        // If no data from new endpoints, try legacy endpoint
        if (threads.length === 0 && allMsgs.length === 0) {
          try {
            const legacyRes = await fetch(`${API_BASE_URL}/chat_message`)
            if (legacyRes.ok) {
              const legacyData = await legacyRes.json()
              const legacyMsgs = Array.isArray(legacyData) ? legacyData : (legacyData.data || [])
              console.log('Fetched legacy messages:', legacyMsgs.length, legacyMsgs)
              
              // Group legacy messages by chat_id to create threads
              const chatMap: { [chatId: string]: any[] } = {}
              legacyMsgs.forEach((msg: any) => {
                const chatId = msg.chat_id || msg.chatId
                if (!chatMap[chatId]) chatMap[chatId] = []
                chatMap[chatId].push(msg)
              })
              
              // Create threads from legacy messages
              threads = Object.entries(chatMap).map(([chatId, msgs]) => {
                const sorted = msgs.sort((a: any, b: any) => 
                  new Date(a.timestamp || a.created_at || 0).getTime() - 
                  new Date(b.timestamp || b.created_at || 0).getTime()
                )
                const last = sorted[sorted.length - 1]
                return {
                  id: chatId,
                  user_id: last.sender_id === currentUserId ? last.receiver_id : last.sender_id,
                  patient_identifier: last.sender_id === currentUserId ? last.receiver_id : last.sender_id,
                  health_worker_id: currentUserId,
                  last_message: last.message || last.reply,
                  last_message_time: last.timestamp || last.created_at,
                  created_at: sorted[0].timestamp || sorted[0].created_at,
                  unread_count: msgs.filter((m: any) => !m.is_read && m.receiver_id === currentUserId).length,
                }
              })
              
              // Map legacy messages to new format
              allMsgs = legacyMsgs.map((msg: any) => ({
                id: msg.id,
                thread_id: msg.chat_id || msg.chatId,
                sender_id: msg.sender_id,
                receiver_id: msg.receiver_id,
                message: msg.message || msg.reply,
                created_at: msg.timestamp || msg.created_at,
                is_read: msg.is_read || false,
                sender_type: msg.sender_id === currentUserId ? 'health_worker' : 'patient',
              }))
            }
          } catch (e) {
            console.error('Failed to fetch legacy chat_message:', e)
          }
        }
        
        // Map messages to our format
        const mappedMessages: MessageDoc[] = allMsgs
          .filter((msg: any) => msg.message || msg.text) // Filter out empty messages
          .map((msg: any) => ({
            id: msg.id,
            threadId: msg.thread_id || msg.chat_id || msg.chatId,
            senderId: msg.sender_id || '',
            receiverId: msg.receiver_id || '',
            text: msg.message || msg.text || '',
            timestamp: msg.created_at || msg.timestamp || msg.last_updated || new Date().toISOString(),
            read: msg.is_read || false,
            senderType: msg.sender_type || (msg.sender_id === currentUserId ? 'health_worker' : 'patient'),
          }))
        
        console.log('Mapped messages:', mappedMessages.length, mappedMessages)
        setAllMessages(mappedMessages)
        
        // Map threads to chat summaries
        const chatSummaries: ChatSummary[] = threads
          .filter((thread: any) => thread.id) // Filter out invalid threads
          .map((thread: any) => {
            const threadMessages = mappedMessages.filter(m => 
              String(m.threadId) === String(thread.id)
            )
            const sortedMsgs = threadMessages.sort((a, b) => 
              new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
            )
            const lastMsg = sortedMsgs[sortedMsgs.length - 1]
            
            return {
              id: thread.id,
              threadId: thread.id,
              userId: thread.user_id || thread.patient_identifier || thread.userId || 'Unknown',
              patientId: thread.patient_id,
              patientName: thread.patient_name || thread.user_id || thread.patient_identifier || 'Unknown',
              patientIdentifier: thread.patient_identifier || thread.user_id,
              healthWorkerId: thread.health_worker_id || 'health_worker',
              lastMessage: thread.last_message || lastMsg?.text || 'No messages',
              lastMessageTime: thread.last_message_time || lastMsg?.timestamp,
              createdAt: thread.created_at || new Date().toISOString(),
              unreadCount: thread.unread_count || sortedMsgs.filter(m => !m.read && m.receiverId === currentUserId).length,
            }
          })
        
        console.log('Chat summaries:', chatSummaries.length, chatSummaries)
        
        // Sort by last message time
        chatSummaries.sort((a, b) => {
          const timeA = new Date(a.lastMessageTime || a.createdAt).getTime()
          const timeB = new Date(b.lastMessageTime || b.createdAt).getTime()
          return timeB - timeA
        })
        
        setChats(chatSummaries)
      } catch (error) {
        console.error("Error fetching chats:", error)
        setChats([])
        setAllMessages([])
      } finally {
        setLoadingChats(false)
      }
    }
    fetchChats()
  }, [])

  // Function to fetch and update messages (using refs to avoid stale closures)
  const fetchAndUpdateMessages = useRef<() => Promise<void>>()
  
  fetchAndUpdateMessages.current = async () => {
    try {
      const messagesRes = await fetch(`${API_BASE_URL}/chat_messages`)
      if (!messagesRes.ok) return
      
      const messagesData = await messagesRes.json()
      const allMsgs = Array.isArray(messagesData) ? messagesData : (messagesData.data || [])
      
      // Map messages to our format
      const mappedMessages: MessageDoc[] = allMsgs
        .filter((msg: any) => msg.message || msg.text)
        .map((msg: any) => ({
          id: msg.id,
          threadId: msg.thread_id,
          senderId: msg.sender_id || '',
          receiverId: msg.receiver_id || '',
          text: msg.message || msg.text || '',
          timestamp: msg.created_at || msg.timestamp || msg.last_updated || new Date().toISOString(),
          read: msg.is_read || false,
          senderType: msg.sender_type,
        }))
      
      // Check if there are new messages (compare by IDs, not just count)
      const currentIds = new Set(allMessages.map(m => m.id))
      const newIds = new Set(mappedMessages.map(m => m.id))
      const hasNewMessages = mappedMessages.length !== allMessages.length || 
                            [...newIds].some(id => !currentIds.has(id))
      
      if (hasNewMessages) {
        setAllMessages(mappedMessages)
        
        // Update current thread messages if a chat is selected
        setMessages(prev => {
          if (!selectedChat) return prev
          
          const threadMessages = mappedMessages
            .filter(m => {
              const match = String(m.threadId) === String(selectedChat.threadId) || 
                           String(m.threadId) === String(selectedChat.id)
              return match && m.text && m.senderId
            })
            .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
          
          // Only update if messages actually changed
          if (threadMessages.length !== prev.length || 
              threadMessages.some((m, i) => m.id !== prev[i]?.id)) {
            return threadMessages
          }
          return prev
        })
      }
    } catch (error) {
      console.error("Error fetching messages:", error)
    }
  }

  // When a chat is selected, fetch and show messages for that thread
  useEffect(() => {
    if (!selectedChat) {
      setMessages([])
      return
    }
    
    const fetchThreadMessages = async () => {
      setLoadingMessages(true)
      try {
        // Filter messages by thread_id (handle both string and number comparison)
        const threadMessages = allMessages
          .filter(m => {
            const match = String(m.threadId) === String(selectedChat.threadId) || 
                         String(m.threadId) === String(selectedChat.id)
            return match && m.text && m.senderId
          })
          .sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime())
        
        console.log('Filtered messages for thread:', selectedChat.threadId, threadMessages.length, threadMessages)
        setMessages(threadMessages)
        lastMessageCountRef.current = allMessages.length
      } catch (error) {
        console.error("Error fetching thread messages:", error)
        setMessages([])
      } finally {
        setLoadingMessages(false)
      }
    }
    
    fetchThreadMessages()
  }, [selectedChat, allMessages])

  // Auto-refresh messages every 3 seconds
  useEffect(() => {
    // Clear any existing interval
    if (pollingIntervalRef.current) {
      clearInterval(pollingIntervalRef.current)
    }
    
    // Set up polling interval
    pollingIntervalRef.current = setInterval(() => {
      if (fetchAndUpdateMessages.current) {
        fetchAndUpdateMessages.current()
      }
    }, 3000) // Poll every 3 seconds
    
    // Initial fetch
    if (fetchAndUpdateMessages.current) {
      fetchAndUpdateMessages.current()
    }
    
    // Cleanup on unmount
    return () => {
      if (pollingIntervalRef.current) {
        clearInterval(pollingIntervalRef.current)
      }
    }
  }, [selectedChat, allMessages]) // Re-run when selected chat or messages change

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
      // Use new admin endpoint for chat_messages table
      const res = await fetch(`${API_BASE_URL}/api/admin/chat_messages`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          thread_id: selectedChat.threadId,
          sender_id: 'health_worker',
          receiver_id: selectedChat.userId || selectedChat.patientIdentifier,
          message: replyContent,
          patient_id: selectedChat.patientId || null,
        })
      })
      
      if (!res.ok) {
        const errorData = await res.json().catch(() => ({ error: 'Failed to send message' }))
        const errorMessage = errorData.error || errorData.message || 'Failed to send message'
        console.error('Error response:', errorData)
        throw new Error(errorMessage)
      }
      
      const msg = await res.json()
      
      // Create new message object
      const newMsg: MessageDoc = {
        id: msg.id || Date.now(),
        threadId: msg.thread_id || selectedChat.threadId,
        senderId: msg.sender_id || 'health_worker',
        receiverId: msg.receiver_id || selectedChat.userId,
        text: msg.message || replyContent,
        timestamp: msg.timestamp || msg.created_at || new Date().toISOString(),
        read: msg.is_read ?? false,
        senderType: 'health_worker',
      }
      
      // Add to messages and allMessages
      setMessages(prev => [...prev, newMsg])
      setAllMessages(prev => [...prev, newMsg])
      
      // Update chat's last message
      setChats(prev => prev.map(chat => 
        chat.id === selectedChat.id 
          ? { ...chat, lastMessage: replyContent, lastMessageTime: newMsg.timestamp }
          : chat
      ))
      
      setReplyContent("")
      
      // Immediately refresh messages after sending
      if (fetchAndUpdateMessages.current) {
        await fetchAndUpdateMessages.current()
      }
      
      // Refresh threads to update last message
      setTimeout(async () => {
        try {
          const threadsRes = await fetch(`${API_BASE_URL}/chat_threads`)
          if (threadsRes.ok) {
            const threadsData = await threadsRes.json()
            const threads = Array.isArray(threadsData) ? threadsData : (threadsData.data || [])
            
            const updatedChats = threads.map((thread: any) => {
              const existingChat = chats.find(c => c.threadId === thread.id)
              return {
                id: thread.id,
                threadId: thread.id,
                userId: thread.user_id || thread.patient_identifier || 'Unknown',
                patientId: thread.patient_id,
                patientName: thread.patient_name || thread.user_id || 'Unknown',
                patientIdentifier: thread.patient_identifier,
                healthWorkerId: thread.health_worker_id || 'health_worker',
                lastMessage: thread.last_message || existingChat?.lastMessage || 'No messages',
                lastMessageTime: thread.last_message_time || existingChat?.lastMessageTime,
                createdAt: thread.created_at || existingChat?.createdAt || new Date().toISOString(),
                unreadCount: thread.unread_count || existingChat?.unreadCount || 0,
              }
            })
            
            setChats(updatedChats)
          }
        } catch (error) {
          console.error("Error refreshing chats:", error)
        }
      }, 500)
    } catch (error) {
      console.error("Error sending reply:", error)
      alert("Error sending reply: " + (error as any).message)
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="flex flex-col sm:flex-row h-[calc(100vh-8rem)] sm:h-[80vh] bg-gray-50 rounded-lg shadow overflow-hidden">
      {/* Sidebar - Mobile: full width, Desktop: 1/4 width */}
      <div className="w-full sm:w-1/4 sm:min-w-[220px] sm:max-w-xs border-r border-gray-200 flex flex-col bg-white">
        <div className="p-3 sm:p-4 border-b bg-white">
          <h2 className="text-base sm:text-lg font-bold text-maternal-blue-700">Chats</h2>
        </div>
        <div className="flex-1 overflow-y-auto">
          {loadingChats ? (
            <div className="text-center text-gray-500 py-8 text-sm">Loading chats...</div>
          ) : (
            <div className="divide-y">
              {chats.map(chat => (
                <div
                  key={chat.id}
                  className={`flex items-center gap-2 px-3 sm:px-4 py-2 sm:py-3 cursor-pointer hover:bg-blue-50 transition ${selectedChat?.id === chat.id ? 'bg-blue-100' : ''}`}
                  onClick={() => setSelectedChat(chat)}
                >
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-maternal-blue-700 truncate text-sm sm:text-base">
                      {chat.patientName || chat.userId || chat.patientIdentifier || 'Unknown'}
                    </div>
                    <div className="text-xs text-gray-500 truncate mt-0.5">{chat.lastMessage}</div>
                  </div>
                  {Number(chat.unreadCount || 0) > 0 && (
                    <span className="ml-2 inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 sm:px-2 rounded-full bg-red-500 text-white text-[10px] sm:text-xs font-bold shrink-0" title="Unread">
                      {chat.unreadCount || 0}
                    </span>
                  )}
                </div>
              ))}
              {chats.length === 0 && !loadingChats && (
                <div className="text-center text-gray-400 py-8 text-sm px-4">
                  <MessageSquare className="h-8 w-8 mx-auto mb-2 text-gray-300" />
                  <p>No chats found.</p>
                  <p className="text-xs mt-2 text-gray-500">Check console for debugging info.</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
      
      {/* Main Chat Area - Mobile: full width, Desktop: 3/4 width */}
      <div className="w-full sm:w-3/4 flex flex-col h-full min-h-[60vh] sm:min-h-[80vh]">
        {selectedChat ? (
          <>
            {/* Chat Header */}
            <div className="border-b px-3 sm:px-6 py-2 sm:py-3 flex items-center gap-2 bg-white sticky top-0 z-10">
              <User className="h-4 w-4 sm:h-5 sm:w-5 text-maternal-blue-500 shrink-0" />
              <span className="font-semibold text-maternal-blue-700 text-sm sm:text-base truncate flex-1">
                {selectedChat.patientName || selectedChat.userId || selectedChat.patientIdentifier || 'Unknown'}
              </span>
              <span className="ml-auto text-[10px] sm:text-xs text-gray-400 hidden sm:block shrink-0">
                {selectedChat.createdAt 
                  ? new Date(selectedChat.createdAt).toLocaleDateString()
                  : 'New chat'}
              </span>
            </div>
            
            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-3 sm:px-6 py-3 sm:py-4 bg-gray-50 flex flex-col" style={{ minHeight: 0 }}>
              {loadingMessages ? (
                <div className="text-center text-gray-500 py-8 text-sm">Loading messages...</div>
              ) : (
                <div className="flex flex-col gap-2 flex-1 justify-end">
                  {messages.map(msg => (
                    <div
                      key={msg.id}
                      className={`flex ${msg.senderId === 'health_worker' || msg.senderType === 'health_worker' ? 'justify-end' : 'justify-start'}`}
                    >
                      <div className={`rounded-2xl px-3 sm:px-4 py-2 max-w-[85%] sm:max-w-[70%] break-words shadow-sm ${
                        msg.senderId === 'health_worker' || msg.senderType === 'health_worker'
                          ? 'bg-maternal-blue-600 text-white' 
                          : 'bg-white text-gray-900 border border-gray-200'
                      }`}>
                        <div className="text-xs sm:text-sm">{msg.text}</div>
                        <div className={`text-[10px] sm:text-xs mt-1 ${
                          msg.senderId === 'health_worker' || msg.senderType === 'health_worker'
                            ? 'text-white/80 text-right' 
                            : 'text-gray-500 text-right'
                        }`}>
                          {msg.timestamp 
                            ? new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
                            : ''}
                        </div>
                      </div>
                    </div>
                  ))}
                  <div ref={messagesEndRef} />
                  {messages.length === 0 && (
                    <div className="text-center text-gray-400 py-8 text-sm">No messages yet.</div>
                  )}
                </div>
              )}
            </div>
            
            {/* Reply Box */}
            <div className="border-t px-3 sm:px-6 py-3 sm:py-4 bg-white flex items-center gap-2 sticky bottom-0 z-10">
              <Textarea
                value={replyContent}
                onChange={e => setReplyContent(e.target.value)}
                placeholder="Type your message..."
                rows={2}
                className="flex-1 resize-none text-sm"
                disabled={sending}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault()
                    handleSendReply()
                  }
                }}
              />
              <Button
                onClick={handleSendReply}
                className="bg-maternal-blue-600 hover:bg-maternal-blue-700 text-white shrink-0 h-auto py-2 sm:py-2.5 px-3 sm:px-4"
                disabled={sending || !replyContent.trim()}
              >
                <Send className="h-4 w-4 sm:mr-2" />
                <span className="hidden sm:inline">Send</span>
              </Button>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400 text-sm sm:text-base px-4">
            <div className="text-center">
              <MessageSquare className="h-12 w-12 sm:h-16 sm:w-16 mx-auto mb-4 text-gray-300" />
              <p>Select a chat to view messages</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
} 